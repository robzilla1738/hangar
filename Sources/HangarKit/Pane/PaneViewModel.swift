// PaneViewModel — owns one TerminalEmulator instance plus the per-pane
// agent state machine. Observes the emulator's outputStream, runs a
// ShellCommandDetector to spot agent invocations, swaps the AgentRegexParser
// when a new agent is detected, and publishes status + model + pending
// approvals + pending cost events via @Observable so the chrome can react.

import AppKit
import Foundation
import HangarCore
import SwiftUI

@MainActor
@Observable
public final class PaneViewModel: Identifiable {
    public let id: UUID
    public let emulator: TerminalEmulator

    /// Focus state — driven by AppKit first responder.
    public var hasFocus: Bool = false

    /// Live agent state, all populated by `startObserving`.
    public var detectedAgentID: AgentProfileID?
    public var detectedAgentDisplayName: String?
    public var model: String?
    public var currentStatus: AgentStatus = .idle
    public var pendingApprovals: [ApprovalItem] = []
    public var pendingCostEvents: [CostEvent] = []
    public var lastBytesReceived: Int = 0

    /// Display title (set from OSC 2 / OSC 7 in Phase 5+; defaults to "Terminal").
    public var title: String = "Terminal"

    /// Detection internals — kept non-observable.
    @ObservationIgnored private var shellDetector = ShellCommandDetector()
    @ObservationIgnored private var parser: any AgentOutputParser = NoopAgentParser()
    @ObservationIgnored private var observationTask: Task<Void, Never>?

    public init(
        emulator: TerminalEmulator = SwiftTermEmulator(),
        autostart config: TerminalStartConfig? = .zshLogin
    ) {
        self.id = emulator.id
        self.emulator = emulator
        if let config {
            emulator.start(
                command: config.command,
                args: config.args,
                env: config.env,
                cwd: config.cwd
            )
        }
        startObserving()
    }

    deinit {
        observationTask?.cancel()
    }

    /// Begin consuming the emulator's outputStream.
    public func startObserving() {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await chunk in self.emulator.outputStream {
                self.consume(chunk)
            }
        }
    }

    /// Consume a chunk of raw bytes: feed it through the shell-command
    /// detector (which may swap the active agent profile), then through the
    /// active parser to extract events.
    func consume(_ chunk: Data) {
        lastBytesReceived = chunk.count
        guard let text = String(data: chunk, encoding: .utf8) else { return }

        let commands = shellDetector.consume(text)
        for cmd in commands {
            let profile = AgentRegistry.shared.resolve(binaryName: cmd)
            if profile.id != "raw_shell" {
                applyProfile(profile)
            }
        }

        let events = parser.feed(chunk)
        for event in events {
            apply(event)
        }
    }

    private func applyProfile(_ profile: AgentProfile) {
        if detectedAgentID == profile.id { return }
        detectedAgentID = profile.id
        detectedAgentDisplayName = profile.displayName
        model = profile.defaultModelHint
        parser = profile.makeParser()
        currentStatus = .idle
    }

    private func apply(_ event: AgentEvent) {
        switch event {
        case .stateChanged(let status):
            currentStatus = status
        case .approvalPrompt(let prompt):
            let agentID = detectedAgentID ?? "unknown"
            pendingApprovals.append(
                ApprovalItem(paneID: id, agentID: agentID, prompt: prompt)
            )
        case .tokenUsage(let input, let output, let cached):
            let modelName = model ?? "unknown"
            let provider = providerFromCurrentAgent()
            let pricing = PricingTable.pricing(for: modelName)
            let cost = pricing?.cost(input: input, output: output, cached: cached) ?? 0.0
            let event = CostEvent(
                paneID: id,
                agentProfileID: detectedAgentID ?? "unknown",
                provider: provider,
                model: modelName,
                inputTokens: input,
                outputTokens: output,
                cachedInputTokens: cached,
                costUSD: cost
            )
            pendingCostEvents.append(event)
        case .fileEdited, .messageEmitted:
            break  // consumed by other surfaces in later phases
        }
    }

    private func providerFromCurrentAgent() -> Provider {
        guard let id = detectedAgentID else { return .none }
        switch id {
        case "claude_code": return .anthropic
        case "codex": return .openai
        case "hermes": return .nous
        default: return .other
        }
    }

    /// Test hook — drain any pending approval/cost events the test wants to consume.
    ///
    /// Production code reads the @Observable arrays directly.
    public func drainPendingApprovals() -> [ApprovalItem] {
        let copy = pendingApprovals
        pendingApprovals.removeAll()
        return copy
    }

    public func drainPendingCostEvents() -> [CostEvent] {
        let copy = pendingCostEvents
        pendingCostEvents.removeAll()
        return copy
    }
}
