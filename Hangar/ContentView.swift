// Hangar — content shell. Phase 4 wires WindowRootView with splittable panes.

import HangarCore
import HangarKit
import SwiftUI

struct ContentView: View {
    @State private var windowViewModel = WindowViewModel()

    var body: some View {
        WindowRootView(viewModel: windowViewModel)
            .ignoresSafeArea()
            .focusedSceneValue(\.windowViewModel, windowViewModel)
    }
}

/// FocusedSceneValue plumbing so Commands can reach the active window's view model.
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
    ContentView()
}
