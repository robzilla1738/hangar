// SwiftTermEmulatorTests — exercise the emulator's PTY lifecycle with a
// trivial command that exits immediately, and verify recentLines reads
// from the buffer without crashing.

import AppKit
import XCTest

@testable import HangarCore

@MainActor
final class SwiftTermEmulatorTests: XCTestCase {
    func testRecentLinesEmptyBeforeStart() {
        let emulator = SwiftTermEmulator()
        XCTAssertEqual(emulator.recentLines(5), [])
    }

    func testStartSetsIsRunningTrue() {
        let emulator = SwiftTermEmulator()
        emulator.start(
            command: "/bin/echo",
            args: ["hello-hangar"],
            env: [:],
            cwd: nil
        )
        XCTAssertTrue(emulator.isRunning)
    }

    func testDoubleStartIsNoop() {
        let emulator = SwiftTermEmulator()
        emulator.start(command: "/bin/echo", args: ["a"], env: [:], cwd: nil)
        let firstView = emulator.view
        emulator.start(command: "/bin/echo", args: ["b"], env: [:], cwd: nil)
        XCTAssertTrue(emulator.isRunning)
        XCTAssertIdentical(firstView, emulator.view)
    }
}
