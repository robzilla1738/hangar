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
                .frame(minWidth: 720, minHeight: 420)
                .task { await appState.bootstrapConfig() }
                .background(WindowConfigurator())
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Hangar") {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    if let url = URL(string: "hangar://new-window") {
                        NSWorkspace.shared.open(url)
                    }
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
}

/// Configures the host NSWindow with a clean Ghostty-style title bar.
///
/// Dark window background, transparent title bar with full-size content,
/// hidden title text. Traffic lights sit in their own ~28pt strip; the
/// terminal padding inside the content view keeps the prompt clear of
/// the buttons.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = NSColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)
            window.isMovableByWindowBackground = false
            window.toolbarStyle = .unified
            // Sensible default size so the terminal has room to breathe
            // without the user needing to resize on first launch.
            if window.frame.size.width < 900 || window.frame.size.height < 560 {
                let screen = window.screen ?? NSScreen.main
                let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                let size = NSSize(width: 960, height: 600)
                let origin = NSPoint(
                    x: visible.midX - size.width / 2,
                    y: visible.midY - size.height / 2
                )
                window.setFrame(NSRect(origin: origin, size: size), display: true)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
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
            // Keep defaults if we can't read the file; banner UX lands later.
        }
    }
}
