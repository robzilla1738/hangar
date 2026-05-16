// WindowRootView — top-level SwiftUI view for one Hangar window.
// Renders the pane tree and routes focus from clicks back to the WindowViewModel.

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
        .background(.windowBackground)
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
        if active {
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(Color.accentColor.opacity(0.75), lineWidth: 1)
                .allowsHitTesting(false)
        } else {
            EmptyView()
        }
    }
}
