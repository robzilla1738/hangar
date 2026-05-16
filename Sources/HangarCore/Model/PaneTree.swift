// PaneTree — recursive model for splits and panes within a tab.
// One Tab owns one PaneNode (root). A PaneNode is either a leaf (single
// pane identifier) or an internal node (split with two children + ratio).

import Foundation

public enum SplitOrientation: String, Codable, Sendable {
    case horizontal  // children left-right; divider vertical
    case vertical  // children top-bottom; divider horizontal
}

public indirect enum PaneNode: Codable, Sendable, Equatable, Identifiable {
    case pane(id: UUID)
    case split(id: UUID, orientation: SplitOrientation, ratio: CGFloat, children: [PaneNode])

    public var id: UUID {
        switch self {
        case .pane(let id), .split(let id, _, _, _):
            return id
        }
    }

    /// All leaf pane IDs in left-to-right depth-first order.
    public var paneIDs: [UUID] {
        switch self {
        case .pane(let id):
            return [id]
        case .split(_, _, _, let children):
            return children.flatMap { $0.paneIDs }
        }
    }

    /// Number of leaf panes.
    public var paneCount: Int { paneIDs.count }

    /// Replace a leaf with a new subtree.
    ///
    /// Returns the modified tree.
    public func replacing(paneID: UUID, with replacement: PaneNode) -> PaneNode {
        switch self {
        case .pane(let id):
            return id == paneID ? replacement : self
        case .split(let id, let orientation, let ratio, let children):
            return .split(
                id: id,
                orientation: orientation,
                ratio: ratio,
                children: children.map { $0.replacing(paneID: paneID, with: replacement) }
            )
        }
    }

    /// Split a leaf into two siblings.
    ///
    /// New pane goes to the right/bottom.
    public func splitting(
        paneID: UUID,
        adding newPaneID: UUID,
        orientation: SplitOrientation
    ) -> PaneNode {
        let split = PaneNode.split(
            id: UUID(),
            orientation: orientation,
            ratio: 0.5,
            children: [.pane(id: paneID), .pane(id: newPaneID)]
        )
        return replacing(paneID: paneID, with: split)
    }

    /// Remove a leaf.
    ///
    /// If the parent split becomes single-child, collapse it.
    /// Returns nil if removing this would leave the tree empty.
    public func removing(paneID: UUID) -> PaneNode? {
        switch self {
        case .pane(let id):
            return id == paneID ? nil : self
        case .split(let id, let orientation, let ratio, let children):
            let filtered = children.compactMap { $0.removing(paneID: paneID) }
            if filtered.isEmpty { return nil }
            if filtered.count == 1 { return filtered[0] }
            return .split(id: id, orientation: orientation, ratio: ratio, children: filtered)
        }
    }
}

public struct Tab: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var title: String
    public var root: PaneNode
    public var activePaneID: UUID

    public init(id: UUID = UUID(), title: String, root: PaneNode, activePaneID: UUID) {
        self.id = id
        self.title = title
        self.root = root
        self.activePaneID = activePaneID
    }

    public static func singlePane(title: String = "Terminal") -> Tab {
        let paneID = UUID()
        return Tab(title: title, root: .pane(id: paneID), activePaneID: paneID)
    }
}

public struct WindowSnapshot: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var projectID: UUID?
    public var tabs: [Tab]
    public var activeTabID: UUID?

    public init(id: UUID = UUID(), projectID: UUID? = nil, tabs: [Tab], activeTabID: UUID? = nil) {
        self.id = id
        self.projectID = projectID
        self.tabs = tabs
        self.activeTabID = activeTabID ?? tabs.first?.id
    }
}
