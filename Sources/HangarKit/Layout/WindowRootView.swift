// WindowRootView — top-level SwiftUI view for one Hangar window.
// Renders the pane tree with the terminal filling every cell.
// Single-pane layouts intentionally render no chrome (Ghostty-style).

import AppKit
import HangarCore
import SwiftUI

public struct WindowRootView: View {
    @Bindable private var viewModel: WindowViewModel

    public init(viewModel: WindowViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        PaneTreeView(node: viewModel.rootNode) { paneID in
            AnyView(
                paneCell(for: paneID)
            )
        }
        .padding(.top, 28)  // Clears the transparent title bar / traffic-light strip
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
    }

    @ViewBuilder
    private func paneCell(for paneID: UUID) -> some View {
        if let paneVM = viewModel.paneViewModels[paneID] {
            TerminalPaneView(viewModel: paneVM)
                .overlay(focusRingOverlay(active: paneID == viewModel.activePaneID))
                .onTapGesture { viewModel.focus(paneID) }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func focusRingOverlay(active: Bool) -> some View {
        // Only show the focus ring when there's more than one pane.
        // Single-pane windows stay completely clean (Ghostty-style).
        if active && viewModel.paneViewModels.count > 1 {
            Rectangle()
                .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1)
                .allowsHitTesting(false)
        } else {
            EmptyView()
        }
    }
}
