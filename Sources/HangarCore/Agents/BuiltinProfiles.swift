// BuiltinProfiles — Claude Code, Codex CLI, Hermes, Raw Shell.
// Each profile owns a stateful AgentOutputParser whose regex patterns
// detect approval prompts and emit events. The parsers are intentionally
// conservative for v0.1; recorded fixtures + tuning live in Phase 6.

import Foundation

// MARK: - Profile structs

public struct ClaudeCodeProfile: AgentProfile {
    public let id: AgentProfileID = "claude_code"
    public let displayName = "Claude Code"
    public let defaultBinaryNames = ["claude"]
    public let provider: Provider = .anthropic
    public let defaultModelHint: String? = "claude-opus-4-7"

    public init() {}

    public func makeParser() -> AgentOutputParser {
        AgentRegexParser(
            approvalPatterns: [
                #"\?\s+\[1\.\s+(?:Allow|Yes|y)\]"#,  // numbered selection
                #"(?i)allow this command\?"#,
                #"(?i)\(y/n\)"#,
                #"(?i)approve.{0,40}\?\s*$"#,
            ],
            thinkingMarkers: ["Thinking…", "thinking..."],
            doneMarkers: ["✓ Done", "✓ complete"]
        )
    }
}

public struct CodexProfile: AgentProfile {
    public let id: AgentProfileID = "codex"
    public let displayName = "Codex CLI"
    public let defaultBinaryNames = ["codex"]
    public let provider: Provider = .openai
    public let defaultModelHint: String? = "gpt-5-codex"

    public init() {}

    public func makeParser() -> AgentOutputParser {
        AgentRegexParser(
            approvalPatterns: [
                #"(?i)run this command\?"#,
                #"(?i)\[y/N\]"#,
                #"(?i)apply (the )?patch\?"#,
            ],
            thinkingMarkers: ["thinking", "planning"],
            doneMarkers: ["Done.", "done."]
        )
    }
}

public struct HermesProfile: AgentProfile {
    public let id: AgentProfileID = "hermes"
    public let displayName = "Hermes"
    public let defaultBinaryNames = ["hermes"]
    public let provider: Provider = .nous
    public let defaultModelHint: String? = "hermes-3-405b"

    public init() {}

    public func makeParser() -> AgentOutputParser {
        AgentRegexParser(
            approvalPatterns: [
                #"(?i)approve.{0,40}\?\s*$"#,
                #"(?i)\(y/n\)"#,
            ],
            thinkingMarkers: ["thinking"],
            doneMarkers: ["done"]
        )
    }
}

public struct RawShellProfile: AgentProfile {
    public let id: AgentProfileID = "raw_shell"
    public let displayName = "Shell"
    public let defaultBinaryNames: [String] = []  // never auto-detected
    public let provider: Provider = .none
    public let defaultModelHint: String? = nil

    public init() {}

    public func makeParser() -> AgentOutputParser {
        NoopAgentParser()
    }
}

// MARK: - Parsers

/// Conservative regex-driven parser used by all built-in agent profiles in v0.1.
struct AgentRegexParser: AgentOutputParser {
    private(set) var status: AgentStatus = .idle

    private let approvalPatterns: [NSRegularExpression]
    private let thinkingMarkers: [String]
    private let doneMarkers: [String]

    init(approvalPatterns: [String], thinkingMarkers: [String], doneMarkers: [String]) {
        self.approvalPatterns = approvalPatterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        }
        self.thinkingMarkers = thinkingMarkers
        self.doneMarkers = doneMarkers
    }

    mutating func feed(_ chunk: Data) -> [AgentEvent] {
        guard let text = String(data: chunk, encoding: .utf8) else { return [] }
        var events: [AgentEvent] = []

        let range = NSRange(text.startIndex..., in: text)
        for pattern in approvalPatterns {
            guard let match = pattern.firstMatch(in: text, range: range) else { continue }
            guard let promptRange = Range(match.range, in: text) else { continue }
            let prompt = String(text[promptRange])
            events.append(.approvalPrompt(prompt: prompt))
            if status != .awaitingApproval {
                status = .awaitingApproval
                events.append(.stateChanged(.awaitingApproval))
            }
            return events
        }

        for marker in thinkingMarkers where text.localizedCaseInsensitiveContains(marker) {
            if status != .thinking {
                status = .thinking
                events.append(.stateChanged(.thinking))
            }
            return events
        }

        for marker in doneMarkers where text.localizedCaseInsensitiveContains(marker) {
            if status != .done {
                status = .done
                events.append(.stateChanged(.done))
            }
            return events
        }

        return events
    }
}

/// No-op parser for the raw shell profile; status stays idle.
struct NoopAgentParser: AgentOutputParser {
    var status: AgentStatus { .idle }
    mutating func feed(_ chunk: Data) -> [AgentEvent] {
        _ = chunk
        return []
    }
}
