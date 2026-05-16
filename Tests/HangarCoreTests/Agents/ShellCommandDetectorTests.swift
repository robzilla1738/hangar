// ShellCommandDetectorTests — confirm command-tokenization fires for common
// prompt formats and ignores non-prompt noise.

import XCTest

@testable import HangarCore

final class ShellCommandDetectorTests: XCTestCase {
    func testDetectsClaudeAtZshPercent() {
        var detector = ShellCommandDetector()
        let cmds = detector.consume("robert@host / % claude\n")
        XCTAssertEqual(cmds, ["claude"])
    }

    func testDetectsCodexAtBashDollar() {
        var detector = ShellCommandDetector()
        let cmds = detector.consume("/usr $ codex --help\n")
        XCTAssertEqual(cmds, ["codex"])
    }

    func testDetectsHermesAtFishChevron() {
        var detector = ShellCommandDetector()
        let cmds = detector.consume("~/work ❯ hermes\n")
        XCTAssertEqual(cmds, ["hermes"])
    }

    func testHandlesChunksSplitMidLine() {
        var detector = ShellCommandDetector()
        let first = detector.consume("robert@host / % cl")
        XCTAssertEqual(first, [])
        let second = detector.consume("aude\n")
        XCTAssertEqual(second, ["claude"])
    }

    func testIgnoresEnvVarAssignments() {
        var detector = ShellCommandDetector()
        let cmds = detector.consume("robert@host / % $VAR=1\n")
        XCTAssertEqual(cmds, [])
    }

    func testIgnoresPlainOutputLines() {
        var detector = ShellCommandDetector()
        let cmds = detector.consume("Hello world\nMore output\n")
        XCTAssertEqual(cmds, [])
    }

    func testDetectsMultipleCommandsInOneChunk() {
        var detector = ShellCommandDetector()
        // Real PTY chunks always terminate lines with \n (the shell echoes
        // the Return keypress) — the trailing newline below mirrors that.
        let cmds = detector.consume(
            "robert@host / % claude\nrobert@host / % codex\n"
        )
        XCTAssertEqual(Set(cmds), Set(["claude", "codex"]))
    }

    func testDedupesDuplicateCommands() {
        var detector = ShellCommandDetector()
        let cmds = detector.consume("$ claude\n$ claude\n")
        XCTAssertEqual(cmds, ["claude"])
    }
}
