// HangarConfigTests — defaults round-trip + JSON5 parse + custom values.

import Foundation
import XCTest

@testable import HangarCore

final class HangarConfigTests: XCTestCase {
    func testDefaultsExistForEverySection() {
        let cfg = HangarConfig.defaults
        XCTAssertEqual(cfg.general.startup, .newWindow)
        XCTAssertEqual(cfg.appearance.theme, "hangar-dark")
        XCTAssertEqual(cfg.appearance.titlebarStyle, .unified)
        XCTAssertEqual(cfg.fonts.family, "SF Mono")
        XCTAssertEqual(cfg.fonts.size, 13)
        XCTAssertEqual(cfg.agents.claudeCode.binary, "claude")
        XCTAssertEqual(cfg.agents.codex.binary, "codex")
        XCTAssertEqual(cfg.agents.hermes.binary, "hermes")
        XCTAssertTrue(cfg.agents.extra.isEmpty)
        XCTAssertEqual(cfg.keybindings.missionControl, "cmd+0")
        XCTAssertEqual(cfg.keybindings.approvalInbox, "cmd+shift+a")
        XCTAssertEqual(cfg.keybindings.newWorktree, "cmd+shift+w")
        XCTAssertEqual(cfg.costs.warnAtUSD, 20.0)
        XCTAssertNil(cfg.costs.hardStopAtUSD)
        XCTAssertEqual(cfg.worktree.baseDir, "~/Hangar/Worktrees")
        XCTAssertFalse(cfg.experimental.useLibghostty)
    }

    func testDefaultTemplateParsesIntoDefaults() throws {
        let raw = Data(ConfigTemplate.defaultContents.utf8)
        let any = try JSONSerialization.jsonObject(with: raw, options: [.json5Allowed])
        let normalized = try JSONSerialization.data(withJSONObject: any)
        let decoded = try JSONDecoder().decode(HangarConfig.self, from: normalized)
        XCTAssertEqual(decoded, .defaults)
    }

    func testJSON5WithCommentsAndTrailingCommasParses() throws {
        let json5Text = """
            // a top-level comment
            {
                general: { startup: "restore_last" },
                appearance: {
                    theme: "hangar-light",
                    transparency: 0.1,
                    titlebar_style: "inset",
                },
                fonts: { family: "JetBrains Mono", size: 15, line_height: 1.3 },
                agents: {
                    claude_code: { binary: "claude" },
                    codex: { binary: "codex" },
                    hermes: { binary: "hermes" },
                    extra: [
                        { name: "aider", binary: "aider", profile: "raw_shell" },
                    ],
                },
                keybindings: {
                    mission_control: "cmd+0",
                    approval_inbox: "cmd+shift+a",
                    new_worktree: "cmd+shift+w",
                },
                costs: { warn_at_usd: 10.0, hard_stop_at_usd: 50.0 },
                worktree: { base_dir: "~/work/wt" },
                experimental: { use_libghostty: true },
            }
            """
        let json5 = Data(json5Text.utf8)
        let any = try JSONSerialization.jsonObject(with: json5, options: [.json5Allowed])
        let normalized = try JSONSerialization.data(withJSONObject: any)
        let cfg = try JSONDecoder().decode(HangarConfig.self, from: normalized)

        XCTAssertEqual(cfg.general.startup, .restoreLast)
        XCTAssertEqual(cfg.appearance.theme, "hangar-light")
        XCTAssertEqual(cfg.appearance.titlebarStyle, .inset)
        XCTAssertEqual(cfg.fonts.family, "JetBrains Mono")
        XCTAssertEqual(cfg.agents.extra.count, 1)
        XCTAssertEqual(cfg.agents.extra.first?.name, "aider")
        XCTAssertEqual(cfg.costs.hardStopAtUSD, 50.0)
        XCTAssertEqual(cfg.worktree.baseDir, "~/work/wt")
        XCTAssertTrue(cfg.experimental.useLibghostty)
    }
}
