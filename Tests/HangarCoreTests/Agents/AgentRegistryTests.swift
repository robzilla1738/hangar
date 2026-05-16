// AgentRegistryTests — binary-name resolution + fallback.

import XCTest

@testable import HangarCore

@MainActor
final class AgentRegistryTests: XCTestCase {
    func testResolvesClaude() {
        let registry = AgentRegistry()
        let profile = registry.resolve(binaryName: "claude")
        XCTAssertEqual(profile.id, "claude_code")
        XCTAssertEqual(profile.provider, .anthropic)
    }

    func testResolvesCodex() {
        let registry = AgentRegistry()
        XCTAssertEqual(registry.resolve(binaryName: "codex").id, "codex")
    }

    func testResolvesHermes() {
        let registry = AgentRegistry()
        XCTAssertEqual(registry.resolve(binaryName: "hermes").id, "hermes")
    }

    func testUnknownBinaryFallsBackToRawShell() {
        let registry = AgentRegistry()
        XCTAssertEqual(registry.resolve(binaryName: "zsh").id, "raw_shell")
        XCTAssertEqual(registry.resolve(binaryName: "vim").id, "raw_shell")
    }

    func testResolvesByLastPathComponent() {
        let registry = AgentRegistry()
        let profile = registry.resolve(binaryName: "/Users/me/.local/bin/claude")
        XCTAssertEqual(profile.id, "claude_code")
    }
}
