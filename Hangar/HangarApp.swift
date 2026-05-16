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
                .task { await appState.bootstrapConfig() }
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

        Settings {
            SettingsView(config: appState.config)
        }
    }
}

@Observable
@MainActor
final class AppState {
    var version: String { HangarCore.version }
    var greeting: String { "Hangar v\(version) — agentic terminal foundation" }
    var config: HangarConfig = .defaults

    private let configStore = ConfigStore()
    private var bootstrapped = false

    func bootstrapConfig() async {
        guard !bootstrapped else { return }
        bootstrapped = true
        do {
            let snapshot = try await configStore.load()
            self.config = snapshot
            try await configStore.watch()
            Task { [weak self] in
                guard let self else { return }
                let stream = await self.configStore.changes
                for await snapshot in stream {
                    await MainActor.run { self.config = snapshot }
                }
            }
        } catch {
            // Keep defaults if we can't read the file; Phase 11 will banner.
        }
    }
}
