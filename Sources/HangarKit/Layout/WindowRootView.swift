// WindowRootView — top-level SwiftUI view for one Hangar window.
// Composes the WindowOverlayBar (top) with the recursive pane tree.

import AppKit
import HangarCore
import SwiftUI

public struct WindowRootView: View {
    @Bindable private var viewModel: WindowViewModel
    private let overlayBarBuilder: () -> AnyView

    public init(
        viewModel: WindowViewModel,
        @ViewBuilder overlayBar: @escaping () -> some View = { EmptyView() }
    ) {
        self.viewModel = viewModel
        self.overlayBarBuilder = { AnyView(overlayBar()) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            overlayBarBuilder()
            paneArea
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
    }

    private var paneArea: some View {
        PaneTreeView(node: viewModel.rootNode) { paneID in
            AnyView(paneCell(for: paneID))
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
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
        if active && viewModel.paneViewModels.count > 1 {
            Rectangle()
                .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1)
                .allowsHitTesting(false)
        } else {
            EmptyView()
        }
    }
}
