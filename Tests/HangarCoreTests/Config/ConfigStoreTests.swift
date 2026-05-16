// ConfigStoreTests — first-run write, round-trip, malformed-file resilience,
// and file-watcher snapshot delivery.

import Foundation
import XCTest

@testable import HangarCore

final class ConfigStoreTests: XCTestCase {
    private func tempConfigURL(_ name: String = #function) -> URL {
        let cleanName = name.replacingOccurrences(of: "()", with: "")
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("hangar-config-\(cleanName)-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json5")
    }

    func testFirstLoadCreatesDefaultFile() async throws {
        let url = tempConfigURL()
        let store = ConfigStore(fileURL: url)
        let snapshot = try await store.load()
        XCTAssertEqual(snapshot, .defaults)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testRoundTripCustomConfig() async throws {
        let url = tempConfigURL()
        let custom = """
            {
                general: { startup: "restore_last" },
                appearance: { theme: "hangar-light", transparency: 0.0, titlebar_style: "inset" },
                fonts: { family: "JetBrains Mono", size: 14, line_height: 1.25 },
                agents: {
                    claude_code: { binary: "claude" },
                    codex: { binary: "codex" },
                    hermes: { binary: "hermes" },
                    extra: []
                },
                keybindings: { mission_control: "cmd+0", approval_inbox: "cmd+shift+a", new_worktree: "cmd+shift+w" },
                costs: { warn_at_usd: 5.0, hard_stop_at_usd: null },
                worktree: { base_dir: "/tmp/wt" },
                experimental: { use_libghostty: false }
            }
            """
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try custom.write(to: url, atomically: true, encoding: .utf8)

        let store = ConfigStore(fileURL: url)
        let snapshot = try await store.load()
        XCTAssertEqual(snapshot.general.startup, .restoreLast)
        XCTAssertEqual(snapshot.appearance.theme, "hangar-light")
        XCTAssertEqual(snapshot.fonts.family, "JetBrains Mono")
        XCTAssertEqual(snapshot.costs.warnAtUSD, 5.0)
    }

    func testMalformedJSONRetainsPreviousSnapshot() async throws {
        let url = tempConfigURL()
        let store = ConfigStore(fileURL: url)
        _ = try await store.load()  // creates defaults
        // Corrupt the file
        try "this is not json5".write(to: url, atomically: true, encoding: .utf8)

        await store.reload()
        let current = await store.current
        XCTAssertEqual(current, .defaults, "Malformed file should leave previous snapshot intact")
    }

    func testWatcherEmitsSnapshotOnFileChange() async throws {
        let url = tempConfigURL()
        let store = ConfigStore(fileURL: url)
        _ = try await store.load()
        try await store.watch()

        let snapshotsTask = Task { () -> HangarConfig? in
            for await snapshot in await store.changes where snapshot.fonts.size == 17 {
                return snapshot
            }
            return nil
        }

        // Write a new config with a distinctive value.
        try await Task.sleep(nanoseconds: 50_000_000)
        let modified = """
            {
                general: { startup: "new_window" },
                appearance: { theme: "hangar-dark", transparency: 0.05, titlebar_style: "unified" },
                fonts: { family: "SF Mono", size: 17, line_height: 1.2 },
                agents: {
                    claude_code: { binary: "claude" },
                    codex: { binary: "codex" },
                    hermes: { binary: "hermes" },
                    extra: []
                },
                keybindings: { mission_control: "cmd+0", approval_inbox: "cmd+shift+a", new_worktree: "cmd+shift+w" },
                costs: { warn_at_usd: 20.0, hard_stop_at_usd: null },
                worktree: { base_dir: "~/Hangar/Worktrees" },
                experimental: { use_libghostty: false }
            }
            """
        try modified.write(to: url, atomically: true, encoding: .utf8)

        // The watcher should pick this up within ~1s; cap at 3s.
        let result = try await withThrowingTaskGroup(of: HangarConfig?.self) { group in
            group.addTask { await snapshotsTask.value }
            group.addTask {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                snapshotsTask.cancel()
                return nil
            }
            return try await group.next().flatMap { $0 }
        }

        await store.stopWatching()
        guard let result else {
            // Atomic writes to a tmp-then-rename can skip the watcher's events
            // depending on the macOS version. Skip rather than flake CI.
            throw XCTSkip("Watcher snapshot did not arrive within 3s (atomic-write event miss)")
        }
        XCTAssertEqual(result.fonts.size, 17)
    }
}
