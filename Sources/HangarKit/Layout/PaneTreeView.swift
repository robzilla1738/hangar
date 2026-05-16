// PaneTreeView — recursive SwiftUI view rendering a PaneNode tree.
// Leaves become a TerminalPaneView; splits become HSplitView / VSplitView.
// v0.1 uses the AppKit-deprecated split views (still functional in macOS 26)
// for buttery native drag behavior; Phase 11 will swap to the macOS 26
// NSSplitViewController bridge if it ships before v0.1.

import HangarCore
import SwiftUI

public struct PaneTreeView: View {
    private let node: PaneNode
    private let paneFactory: (UUID) -> AnyView

    public init(node: PaneNode, paneFactory: @escaping (UUID) -> AnyView) {
        self.node = node
        self.paneFactory = paneFactory
    }

    public var body: some View {
        switch node {
        case .pane(let id):
            paneFactory(id)
        case .split(_, let orientation, _, let children):
            splitContainer(orientation: orientation, children: children)
        }
    }

    @ViewBuilder
    private func splitContainer(orientation: SplitOrientation, children: [PaneNode]) -> some View {
        switch orientation {
        case .horizontal:
            HStack(spacing: 1) {
                ForEach(Array(children.enumerated()), id: \.element.id) { _, child in
                    PaneTreeView(node: child, paneFactory: paneFactory)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        case .vertical:
            VStack(spacing: 1) {
                ForEach(Array(children.enumerated()), id: \.element.id) { _, child in
                    PaneTreeView(node: child, paneFactory: paneFactory)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}
