// Hangar — native macOS agentic terminal.
// © 2026 Robert Courson and Hangar contributors. MIT License.

import HangarCore
import HangarKit
import SwiftUI

@main
struct HangarApp: App {
    @State private var appState = AppState()
    @FocusedValue(\.windowViewModel) private var focusedWindow: WindowViewModel?

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
                    openNewWindow()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandMenu("View") {
                Button("Split Horizontally") {
                    focusedWindow?.splitActive(orientation: .horizontal)
                }
                .keyboardShortcut("d", modifiers: [.command])
                .disabled(focusedWindow == nil)

                Button("Split Vertically") {
                    focusedWindow?.splitActive(orientation: .vertical)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                .disabled(focusedWindow == nil)

                Divider()

                Button("Close Pane") {
                    focusedWindow?.closeActive()
                }
                .keyboardShortcut("w", modifiers: [.command])
                .disabled(focusedWindow == nil)
            }
        }

        Settings {
            SettingsView(config: appState.config)
        }
    }

    private func openNewWindow() {
        // SwiftUI's WindowGroup handles Cmd-N via the default newItem command;
        // we replaced .newItem to ensure both the menu and shortcut work.
        if let url = URL(string: "hangar://new-window") {
            NSWorkspace.shared.open(url)
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
