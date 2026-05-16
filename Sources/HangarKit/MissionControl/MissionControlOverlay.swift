// MissionControlOverlay — full-window grid presented over the active window.
// Phase 11 will lift it into a separate NSWindow with a HUD material backdrop.

import HangarCore
import SwiftUI

public struct MissionControlOverlay: View {
    /// Open-animation duration; asserted in tests.
    public static let openAnimationDuration: TimeInterval = 0.3

    /// Tile cascade stagger (ms per tile); asserted positive in tests.
    public static let tileCascadeStaggerMS: Double = 50

    private let snapshots: [AgentTileSnapshot]
    private let onSelect: (AgentTileSnapshot) -> Void
    private let onDismiss: () -> Void

    public init(
        snapshots: [AgentTileSnapshot],
        onSelect: @escaping (AgentTileSnapshot) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.snapshots = snapshots
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if snapshots.isEmpty {
            emptyState
        } else {
            gridContent
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            Text("No active panes")
                .font(.title2.bold())
            Text("Open a window to get started.")
                .foregroundStyle(.secondary)
        }
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 16)],
                spacing: 16
            ) {
                ForEach(MissionControlSorter.sort(snapshots)) { snapshot in
                    AgentTileView(snapshot: snapshot) { onSelect(snapshot) }
                }
            }
            .padding(32)
        }
    }
}

struct AgentTileView: View {
    let snapshot: AgentTileSnapshot
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(snapshot.agentDisplayName)
                        .font(.headline)
                    Spacer()
                    if snapshot.needsAttention {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                    }
                }
                if let model = snapshot.model {
                    Text(model)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                StatusPill(status: snapshot.status, agentName: snapshot.agentDisplayName)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(snapshot.lastLines.prefix(3).enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if snapshot.lastLines.isEmpty {
                        Text("(no recent output)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                HStack {
                    Text("\(snapshot.tokensToday) tokens today")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(snapshot.needsAttention ? .red : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(snapshot.agentDisplayName), \(snapshot.status.rawValue)"))
    }
}
