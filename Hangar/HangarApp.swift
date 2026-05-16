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
                .task { await appState.bootstrap() }
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

                Divider()

                Button("Approval Inbox") {
                    appState.approvalInboxPresented.toggle()
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
            }

            CommandMenu("Debug") {
                Button("Inject Fake Approval") {
                    appState.injectDebugApproval()
                }
                Divider()
                Button("Clear Inbox") {
                    Task { await appState.approvalInbox.clearResolved() }
                }
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
/// overlay bar (in the content view) handles indicators below them.
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
    var config: HangarConfig = .defaults

    /// All open Hangar windows, keyed by WindowViewModel.id.
    var openWindows: [UUID: WindowViewModel] = [:]

    /// Shared inbox + ledger; the chrome subscribes for live state.
    let approvalInbox: ApprovalInbox
    let costLedger: CostLedger

    /// Mirrored chrome state, updated by subscriber tasks.
    var todayCostUSD: Double = 0.0
    var pendingApprovalCount: Int = 0
    var approvalInboxPresented: Bool = false

    private let configStore = ConfigStore()
    private var bootstrapped = false

    init() {
        let inbox = ApprovalInbox()
        let ledger = CostLedger()
        let notifier = NotificationCenterService()
        self.approvalInbox = inbox
        self.costLedger = ledger
        self.awareness = AwarenessAdapter(approvalInbox: inbox, notificationService: notifier)
    }

    /// Run-once startup: config, awareness wiring, notification authorization.
    func bootstrap() async {
        guard !bootstrapped else { return }
        bootstrapped = true

        await wireApprovalInputSink()
        await notificationService.requestAuthorization()
        startApprovalCountSubscription()
        await bootstrapConfig()
    }

    let notificationService = NotificationCenterService()

    /// Single AwarenessAdapter shared by every pane in every window.
    @ObservationIgnored let awareness: AwarenessAdapter

    /// Latest snapshot of inbox items for popover rendering.
    var approvalItems: [ApprovalItem] = []

    private func bootstrapConfig() async {
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
            // Keep defaults; banner UX lands in a later phase.
        }
    }

    private func wireApprovalInputSink() async {
        await approvalInbox.setInputSink { [weak self] paneID, text in
            Task { @MainActor in
                self?.writeToPane(paneID, text)
            }
        }
    }

    private func startApprovalCountSubscription() {
        let inbox = approvalInbox
        Task { [weak self] in
            for await items in await inbox.updates {
                let pending = items.filter { $0.state == .pending }.count
                await MainActor.run {
                    self?.pendingApprovalCount = pending
                    self?.approvalItems = items
                }
            }
        }
    }

    /// Respond to an approval item and let the inbox actor route the
    /// keystroke back to the originating pane via the configured sink.
    func respondToApproval(itemID: UUID, action: ApprovalAction) {
        let inbox = approvalInbox
        Task {
            await inbox.respond(itemID: itemID, action: action)
        }
    }

    /// Inject a synthetic approval item — used by Debug menu and tests
    /// to verify the routing without needing a live agent.
    func injectDebugApproval() {
        guard let firstPane = openWindows.values.first?.paneViewModels.values.first else {
            return
        }
        let item = ApprovalItem(
            paneID: firstPane.id,
            agentID: firstPane.detectedAgentID ?? "debug",
            prompt: "Run `rm -rf node_modules` ? [debug-injected]"
        )
        awareness.report(item, agentDisplayName: "Debug")
        approvalInboxPresented = true
    }

    /// Find a pane across all open windows and write text to its emulator.
    func writeToPane(_ paneID: UUID, _ text: String) {
        for window in openWindows.values {
            if let pane = window.paneViewModels[paneID] {
                pane.emulator.send(text)
                return
            }
        }
    }

    /// Active pane of the most-recently-registered window, used by the
    /// overlay bar to drive its left + center clusters.
    func activePane(in window: WindowViewModel?) -> PaneViewModel? {
        guard let window else { return nil }
        return window.paneViewModels[window.activePaneID]
    }

    /// Best-effort current working directory for the active pane.
    ///
    /// v0.2.0 falls back to the user's home directory; OSC 7 live tracking
    /// from the shell lands in a Phase 8 sub-task.
    func cwdPath(in window: WindowViewModel?) -> String {
        _ = window
        return NSHomeDirectory()
    }

    func registerWindow(_ window: WindowViewModel) {
        openWindows[window.id] = window
        window.bindAwareness(awareness)
    }

    func unregisterWindow(_ window: WindowViewModel) {
        openWindows.removeValue(forKey: window.id)
    }
}
