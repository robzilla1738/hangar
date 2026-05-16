// WindowOverlayBar — Ghostty-clean title-bar strip.
//
// Left: folder icon + cwd path (small, mono, dimmed). Right: agent
// indicators ONLY when something is happening — no permanent buttons,
// no cost tracker, no chrome that fights the terminal for attention.
//
// • approval bell: hidden when count == 0
// • model badge: hidden when no agent detected
// • status pill: hidden when status is .idle
// • Mission Control: keyboard-only (⌘0); no button in chrome
//
// Sits transparently on the dark window background, no material backdrop.
// Height matches the macOS traffic-light strip (~28pt).

import HangarCore
import SwiftUI

public struct WindowOverlayBar: View {
    private let cwdPath: String?
    private let activePane: PaneViewModel?
    private let pendingApprovalCount: Int
    private let onBellTap: () -> Void

    public init(
        cwdPath: String?,
        activePane: PaneViewModel?,
        pendingApprovalCount: Int,
        onBellTap: @escaping () -> Void = {}
    ) {
        self.cwdPath = cwdPath
        self.activePane = activePane
        self.pendingApprovalCount = pendingApprovalCount
        self.onBellTap = onBellTap
    }

    public var body: some View {
        HStack(spacing: 8) {
            cwdCluster
            Spacer(minLength: 8)
            agentCluster
        }
        .padding(.leading, 80)  // clears traffic lights
        .padding(.trailing, 14)
        .frame(height: 28)
    }

    @ViewBuilder
    private var cwdCluster: some View {
        if let path = cwdPath, !path.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text(displayPath(path))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var agentCluster: some View {
        HStack(spacing: 10) {
            if shouldShowStatus {
                StatusPill(
                    status: activePane?.currentStatus ?? .idle,
                    agentName: activePane?.detectedAgentDisplayName
                )
                .transition(.opacity)
            }

            if pendingApprovalCount > 0 {
                ApprovalInboxBell(pendingCount: pendingApprovalCount, onTap: onBellTap)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: pendingApprovalCount)
        .animation(.easeInOut(duration: 0.18), value: activePane?.currentStatus)
    }

    private var shouldShowStatus: Bool {
        guard let pane = activePane else { return false }
        guard pane.detectedAgentID != nil else { return false }
        return pane.currentStatus != .idle
    }

    /// Abbreviates an absolute path the way shells do: `/Users/<me>/Code/terminal` → `~/Code/terminal`.
    private func displayPath(_ raw: String) -> String {
        let home = NSHomeDirectory()
        if raw == home { return "~" }
        if raw.hasPrefix(home + "/") {
            return "~" + raw.dropFirst(home.count)
        }
        return raw
    }
}
