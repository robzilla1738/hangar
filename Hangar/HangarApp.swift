// Hangar — native macOS agentic terminal.
// © 2026 Robert Courson and Hangar contributors. MIT License.

import HangarCore
import HangarKit
import SwiftUI

@main
struct HangarApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup("Hangar", id: "main") {
            ContentView()
                .environment(appState)
                .frame(minWidth: 720, minHeight: 480)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Hangar") {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    NSApp.sendAction(#selector(NSApplication.newWindowForTab(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}

@Observable
@MainActor
final class AppState {
    var version: String { HangarCore.version }
    var greeting: String { "Hangar v\(version) — agentic terminal foundation" }
}
