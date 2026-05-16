// Hangar — content shell. Composes WindowRootView with a Ghostty-clean
// title-bar overlay (folder + cwd left, agent indicators right when
// something is happening) and registers the window with AppState.

import HangarCore
import HangarKit
import SwiftUI

struct ContentView: View {
    @State private var windowViewModel = WindowViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var bindableState = appState
        return WindowRootView(viewModel: windowViewModel) {
            WindowOverlayBar(
                cwdPath: appState.cwdPath(in: windowViewModel),
                activePane: appState.activePane(in: windowViewModel),
                pendingApprovalCount: appState.pendingApprovalCount,
                approvalItems: appState.approvalItems,
                popoverPresented: $bindableState.approvalInboxPresented,
                onBellTap: { appState.approvalInboxPresented.toggle() },
                onApprovalAction: { itemID, action in
                    appState.respondToApproval(itemID: itemID, action: action)
                }
            )
        }
        .focusedSceneValue(\.windowViewModel, windowViewModel)
        .task { appState.registerWindow(windowViewModel) }
        .onDisappear { appState.unregisterWindow(windowViewModel) }
    }
}

struct WindowViewModelFocusKey: FocusedValueKey {
    typealias Value = WindowViewModel
}

extension FocusedValues {
    var windowViewModel: WindowViewModel? {
        get { self[WindowViewModelFocusKey.self] }
        set { self[WindowViewModelFocusKey.self] = newValue }
    }
}

#Preview {
    ContentView().environment(AppState())
}
