// WindowViewModel — owns the pane tree + per-pane view models for one window.
// Splits, focus, and pane creation route through here.

import AppKit
import Foundation
import HangarCore
import SwiftUI

@MainActor
@Observable
public final class WindowViewModel {
    public private(set) var rootNode: PaneNode
    public private(set) var paneViewModels: [UUID: PaneViewModel] = [:]
    public private(set) var activePaneID: UUID

    public init(initial config: TerminalStartConfig = .zshLogin) {
        let firstID = UUID()
        let emulator = SwiftTermEmulator()
        // We need to overlay the emulator's id onto the pane id for the view
        // factory to look it up. Wire the PaneViewModel keyed by an explicit ID.
        let vm = PaneViewModel(emulator: emulator, autostart: config)
        self.paneViewModels = [firstID: vm]
        self.rootNode = .pane(id: firstID)
        self.activePaneID = firstID
    }

    public func splitActive(orientation: SplitOrientation) {
        let newPaneID = UUID()
        let vm = PaneViewModel(emulator: SwiftTermEmulator(), autostart: .zshLogin)
        paneViewModels[newPaneID] = vm
        rootNode = rootNode.splitting(
            paneID: activePaneID,
            adding: newPaneID,
            orientation: orientation
        )
        activePaneID = newPaneID
    }

    public func closeActive() {
        let removingID = activePaneID
        if let newRoot = rootNode.removing(paneID: removingID) {
            rootNode = newRoot
            paneViewModels.removeValue(forKey: removingID)
            if let firstRemaining = rootNode.paneIDs.first {
                activePaneID = firstRemaining
            }
        } else {
            // Last pane — the window will close at the AppKit layer.
            paneViewModels.removeValue(forKey: removingID)
        }
    }

    public func focus(_ id: UUID) {
        guard paneViewModels[id] != nil else { return }
        activePaneID = id
    }
}
