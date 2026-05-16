// Hangar — minimal Ghostty-style content shell.
// One terminal pane filling the entire window, no chrome.

import HangarCore
import HangarKit
import SwiftUI

struct ContentView: View {
    @State private var windowViewModel = WindowViewModel()

    var body: some View {
        WindowRootView(viewModel: windowViewModel)
            .focusedSceneValue(\.windowViewModel, windowViewModel)
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
    ContentView()
}
