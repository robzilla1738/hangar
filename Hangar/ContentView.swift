// Hangar — content shell. Real pane wiring lands in Phase 2.

import HangarCore
import HangarKit
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            BackgroundSurface()

            VStack(spacing: 16) {
                Image(systemName: "terminal")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(.tint)

                Text(appState.greeting)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Terminal panes land in Phase 2.")
                    .foregroundStyle(.secondary)
            }
            .padding(40)
        }
    }
}

#Preview {
    ContentView().environment(AppState())
}
