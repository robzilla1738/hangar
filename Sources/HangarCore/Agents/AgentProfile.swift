// AgentProfile — protocol describing one CLI-agent integration.
// Built-in profiles for Claude Code, Codex CLI, Hermes, and the raw shell
// fallback ship in v0.1. Phase 6 wires the output parser into the Approval
// Inbox; Phase 8 wires its cost parser into the ledger.

import Foundation

public typealias AgentProfileID = String

/// Provider that pays for an agent's tokens.
public enum Provider: String, Codable, Sendable, Equatable {
    case anthropic
    case openai
    case nous
    case google
    case other
    case none
}

/// Possible high-level states reported by an agent.
public enum AgentStatus: String, Codable, Sendable, Equatable {
    case idle
    case thinking
    case runningTool = "running_tool"
    case awaitingApproval = "awaiting_approval"
    case errored
    case done
}

/// Event emitted by an AgentOutputParser as bytes are fed in.
public enum AgentEvent: Sendable, Equatable {
    case stateChanged(AgentStatus)
    case approvalPrompt(prompt: String)
    case tokenUsage(input: Int, output: Int, cached: Int)
    case fileEdited(path: String)
    case messageEmitted(role: String, text: String)
}

/// Stateful parser owned by a pane.
///
/// Fed PTY bytes as they arrive.
public protocol AgentOutputParser: Sendable {
    /// Current high-level status.
    var status: AgentStatus { get }

    /// Feed a chunk of raw output. Returns any events the chunk produced.
    mutating func feed(_ chunk: Data) -> [AgentEvent]
}

/// Describes one CLI agent integration.
public protocol AgentProfile: Sendable {
    /// Stable, machine-readable ID (e.g. "claude_code").
    var id: AgentProfileID { get }

    /// Display name for UI (e.g. "Claude Code").
    var displayName: String { get }

    /// Binary names that should auto-apply this profile on a pane.
    ///
    /// First match wins; case-sensitive against the literal command name.
    var defaultBinaryNames: [String] { get }

    /// Provider funding the tokens.
    var provider: Provider { get }

    /// Hint for the model name shown until output reveals the real one.
    var defaultModelHint: String? { get }

    /// Construct a fresh output parser instance per pane.
    func makeParser() -> AgentOutputParser
}
