// PaneViewModel — owns one TerminalEmulator instance plus UI-level state
// (focus, model badge, status). Wired further in Phase 5 (agent profiles)
// and Phase 6 (status/approval).

import AppKit
import Foundation
import HangarCore
import SwiftUI

@MainActor
@Observable
public final class PaneViewModel: Identifiable {
    public let id: UUID
    public let emulator: TerminalEmulator

    public var hasFocus: Bool = false

    /// Reserved for Phase 5: the detected agent profile's identifier.
    public var detectedAgentID: String?

    /// Reserved for Phase 6: derived agent status.
    public var statusLabel: String = "idle"

    /// Optional title (set by emulator's OSC sequences in Phase 5+).
    public var title: String = "Terminal"

    public init(
        emulator: TerminalEmulator = SwiftTermEmulator(),
        autostart config: TerminalStartConfig = .zshLogin
    ) {
        self.id = emulator.id
        self.emulator = emulator
        emulator.start(
            command: config.command,
            args: config.args,
            env: config.env,
            cwd: config.cwd
        )
    }
}
