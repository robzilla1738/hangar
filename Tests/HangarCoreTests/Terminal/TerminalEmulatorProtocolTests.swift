// TerminalEmulatorProtocolTests — verify SwiftTermEmulator conforms to the
// TerminalEmulator protocol and that startup config defaults are correct.

import AppKit
import XCTest

@testable import HangarCore

@MainActor
final class TerminalEmulatorProtocolTests: XCTestCase {
    func testSwiftTermEmulatorConformsToTerminalEmulator() {
        let emulator: TerminalEmulator = SwiftTermEmulator()
        XCTAssertNotNil(emulator.view)
        XCTAssertFalse(emulator.isRunning)
        XCTAssertNil(emulator.exitCode)
    }

    func testZshLoginConfigDefaults() {
        let config = TerminalStartConfig.zshLogin
        XCTAssertEqual(config.command, "/bin/zsh")
        XCTAssertEqual(config.args, ["-l"])
        XCTAssertEqual(config.env["TERM"], "xterm-256color")
        XCTAssertEqual(config.env["LANG"], "en_US.UTF-8")
        XCTAssertEqual(config.initialCols, 80)
        XCTAssertEqual(config.initialRows, 24)
    }

    func testCustomConfigPropagates() {
        let cwd = URL(fileURLWithPath: "/tmp")
        let config = TerminalStartConfig(
            command: "/bin/bash",
            args: ["-c", "echo hi"],
            env: ["FOO": "bar"],
            cwd: cwd,
            initialCols: 100,
            initialRows: 30
        )
        XCTAssertEqual(config.command, "/bin/bash")
        XCTAssertEqual(config.args, ["-c", "echo hi"])
        XCTAssertEqual(config.env["FOO"], "bar")
        XCTAssertEqual(config.cwd, cwd)
        XCTAssertEqual(config.initialCols, 100)
        XCTAssertEqual(config.initialRows, 30)
    }
}
