// PaneViewModelObservationTests — push synthetic PTY bytes through a fake
// emulator and verify PaneViewModel publishes the right @Observable state.

import AppKit
import Foundation
import HangarCore
import XCTest

@testable import HangarKit

@MainActor
final class FakeTerminalEmulator: NSObject, TerminalEmulator {
    let id = UUID()
    let view = NSView()
    private(set) var attachedProcessID: pid_t?
    private(set) var exitCode: Int32?
    private(set) var isRunning = false

    let outputStream: AsyncStream<Data>
    private let continuation: AsyncStream<Data>.Continuation
    private(set) var written: [String] = []

    override init() {
        let (stream, continuation) = AsyncStream<Data>.makeStream()
        self.outputStream = stream
        self.continuation = continuation
        super.init()
    }

    func push(_ text: String) {
        continuation.yield(Data(text.utf8))
    }

    func finish() {
        continuation.finish()
    }

    func start(command: String, args: [String], env: [String: String], cwd: URL?) {
        _ = (command, args, env, cwd)
        isRunning = true
    }

    func send(_ text: String) {
        written.append(text)
    }

    func resize(cols: Int, rows: Int) {
        _ = (cols, rows)
    }

    func recentLines(_ count: Int) -> [String] {
        _ = count
        return []
    }

    func terminate() {
        isRunning = false
    }
}

@MainActor
final class PaneViewModelObservationTests: XCTestCase {
    private func waitForObservation() async throws {
        // Two run-loop hops to let the @MainActor observation task drain.
        try await Task.sleep(nanoseconds: 50_000_000)
    }

    func testClaudeCommandSetsAgentMetadata() async throws {
        let fake = FakeTerminalEmulator()
        let viewModel = PaneViewModel(emulator: fake, autostart: nil)
        fake.push("robert@host / % claude\n")
        try await waitForObservation()
        XCTAssertEqual(viewModel.detectedAgentID, "claude_code")
        XCTAssertEqual(viewModel.detectedAgentDisplayName, "Claude Code")
        XCTAssertEqual(viewModel.model, "claude-opus-4-7")
    }

    func testCodexCommandSetsAgentMetadata() async throws {
        let fake = FakeTerminalEmulator()
        let viewModel = PaneViewModel(emulator: fake, autostart: nil)
        fake.push("/tmp $ codex\n")
        try await waitForObservation()
        XCTAssertEqual(viewModel.detectedAgentID, "codex")
    }

    func testApprovalPromptCapturedAsItem() async throws {
        let fake = FakeTerminalEmulator()
        let viewModel = PaneViewModel(emulator: fake, autostart: nil)
        fake.push("robert@host / % claude\n")
        try await waitForObservation()
        fake.push("Run `rm -rf node_modules`? [1. Allow]\n")
        try await waitForObservation()
        XCTAssertEqual(viewModel.currentStatus, .awaitingApproval)
        XCTAssertEqual(viewModel.pendingApprovals.count, 1)
        XCTAssertEqual(viewModel.pendingApprovals.first?.agentID, "claude_code")
    }

    func testNonAgentStreamLeavesStateIdle() async throws {
        let fake = FakeTerminalEmulator()
        let viewModel = PaneViewModel(emulator: fake, autostart: nil)
        fake.push("Hello world\nNothing here\n")
        try await waitForObservation()
        XCTAssertNil(viewModel.detectedAgentID)
        XCTAssertEqual(viewModel.currentStatus, .idle)
        XCTAssertTrue(viewModel.pendingApprovals.isEmpty)
    }
}
