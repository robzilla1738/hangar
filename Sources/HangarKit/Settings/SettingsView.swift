// SettingsView — read-only viewer for the current Hangar config (v0.1).
// Phase 11 adds a full editor; for now this surfaces the live snapshot
// so users can confirm hot-reload worked.

import AppKit
import HangarCore
import SwiftUI

public struct SettingsView: View {
    private let config: HangarConfig
    private let configFileURL: URL

    public init(
        config: HangarConfig,
        configFileURL: URL = ConfigPaths.configFileURL
    ) {
        self.config = config
        self.configFileURL = configFileURL
    }

    public var body: some View {
        Form {
            Section("General") {
                LabeledContent("Startup", value: config.general.startup.rawValue)
            }
            Section("Appearance") {
                LabeledContent("Theme", value: config.appearance.theme)
                LabeledContent("Transparency", value: String(format: "%.2f", config.appearance.transparency))
                LabeledContent("Titlebar style", value: config.appearance.titlebarStyle.rawValue)
            }
            Section("Fonts") {
                LabeledContent("Family", value: config.fonts.family)
                LabeledContent("Size", value: "\(config.fonts.size) pt")
                LabeledContent("Line height", value: String(format: "%.2f", config.fonts.lineHeight))
            }
            Section("Agents") {
                LabeledContent("Claude Code binary", value: config.agents.claudeCode.binary)
                LabeledContent("Codex binary", value: config.agents.codex.binary)
                LabeledContent("Hermes binary", value: config.agents.hermes.binary)
                LabeledContent("Custom detectors", value: "\(config.agents.extra.count)")
            }
            Section("Keybindings") {
                LabeledContent("Mission Control", value: config.keybindings.missionControl)
                LabeledContent("Approval Inbox", value: config.keybindings.approvalInbox)
                LabeledContent("New worktree", value: config.keybindings.newWorktree)
            }
            Section("Costs") {
                LabeledContent("Warn at", value: String(format: "$%.2f", config.costs.warnAtUSD))
                LabeledContent(
                    "Hard stop at",
                    value: config.costs.hardStopAtUSD.map { String(format: "$%.2f", $0) } ?? "—"
                )
            }
            Section("Worktree") {
                LabeledContent("Base directory", value: config.worktree.baseDir)
            }
            Section {
                Button("Reveal config in Finder…") {
                    NSWorkspace.shared.activateFileViewerSelecting([configFileURL])
                }
                Text("Edit this file directly; changes hot-reload.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } header: {
                Text("File")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 560)
    }
}

#Preview {
    SettingsView(config: .defaults)
}
