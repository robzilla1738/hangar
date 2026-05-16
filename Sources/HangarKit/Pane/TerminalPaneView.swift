// TerminalPaneView — SwiftUI host for a TerminalEmulator's NSView.
// One pane = one PaneViewModel = one TerminalEmulator instance.

import AppKit
import HangarCore
import SwiftUI

/// SwiftUI wrapper around a TerminalEmulator's rendered NSView.
public struct TerminalPaneView: NSViewRepresentable {
    private let viewModel: PaneViewModel

    public init(viewModel: PaneViewModel) {
        self.viewModel = viewModel
    }

    public func makeNSView(context: Context) -> NSView {
        viewModel.emulator.view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        // Layout adjustments will live in Phase 11 (font/theme propagation).
        // PaneViewModel is @Observable; SwiftUI re-renders on relevant changes.
    }
}
