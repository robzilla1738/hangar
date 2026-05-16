// Hangar — content shell. Phase 2 wires a single TerminalPaneView.

import HangarCore
import HangarKit
import SwiftUI

struct ContentView: View {
    @State private var paneViewModel = PaneViewModel()

    var body: some View {
        TerminalPaneView(viewModel: paneViewModel)
            .background(.windowBackground)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
