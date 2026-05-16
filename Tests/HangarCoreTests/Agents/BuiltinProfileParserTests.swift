// BuiltinProfileParserTests — exercise each profile's parser against
// representative output fragments. Full session fixtures land in Phase 6.

import Foundation
import XCTest

@testable import HangarCore

final class BuiltinProfileParserTests: XCTestCase {
    private func feed(_ profile: AgentProfile, _ text: String) -> [AgentEvent] {
        var parser = profile.makeParser()
        return parser.feed(Data(text.utf8))
    }

    func testClaudeApprovalDetected() {
        let events = feed(ClaudeCodeProfile(), "Run `rm -rf node_modules`? [1. Allow]")
        let hasApproval = events.contains { event in
            if case .approvalPrompt = event { return true }
            return false
        }
        XCTAssertTrue(hasApproval, "Claude approval prompt should fire on numbered selection")
    }

    func testCodexApprovalDetected() {
        let events = feed(CodexProfile(), "Run this command? [y/N]")
        let hasApproval = events.contains { event in
            if case .approvalPrompt = event { return true }
            return false
        }
        XCTAssertTrue(hasApproval, "Codex approval prompt should fire")
    }

    func testHermesYNPromptDetected() {
        let events = feed(HermesProfile(), "Continue with the migration? (y/n)")
        let hasApproval = events.contains { event in
            if case .approvalPrompt = event { return true }
            return false
        }
        XCTAssertTrue(hasApproval, "Hermes y/n prompt should fire")
    }

    func testRawShellNeverEmitsEvents() {
        let events = feed(RawShellProfile(), "any output\n$ ")
        XCTAssertTrue(events.isEmpty)
    }

    func testThinkingTransitionEmitsState() {
        var parser = ClaudeCodeProfile().makeParser()
        let events = parser.feed(Data("Thinking…\n".utf8))
        let hasStateChange = events.contains { event in
            if case .stateChanged(.thinking) = event { return true }
            return false
        }
        XCTAssertTrue(hasStateChange)
        XCTAssertEqual(parser.status, .thinking)
    }

    func testInnocuousOutputDoesNotFireApproval() {
        let events = feed(ClaudeCodeProfile(), "Hello world\nLet me check the file structure first.")
        let hasApproval = events.contains { event in
            if case .approvalPrompt = event { return true }
            return false
        }
        XCTAssertFalse(hasApproval, "Innocuous output should not trigger approval inbox")
    }
}
