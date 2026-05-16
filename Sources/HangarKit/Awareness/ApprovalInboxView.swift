// ApprovalInboxView — popover list of pending approvals + bell button.

import HangarCore
import SwiftUI

public struct ApprovalInboxBell: View {
    private let pendingCount: Int
    private let onTap: () -> Void

    public init(pendingCount: Int, onTap: @escaping () -> Void) {
        self.pendingCount = pendingCount
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 14, weight: .medium))
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.red, in: Capsule())
                        .foregroundStyle(.white)
                        .offset(x: 8, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Approval Inbox: \(pendingCount) pending")
    }
}

public struct ApprovalInboxView: View {
    private let items: [ApprovalItem]
    private let onAction: (UUID, ApprovalAction) -> Void

    public init(items: [ApprovalItem], onAction: @escaping (UUID, ApprovalAction) -> Void) {
        self.items = items
        self.onAction = onAction
    }

    public var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .frame(minWidth: 360, idealWidth: 420, minHeight: 200)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)
            Text("No pending approvals.")
                .font(.headline)
            Text("Your agents are all clear.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(28)
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                ApprovalRow(item: item, onAction: { onAction(item.id, $0) })
                if item.id != items.last?.id {
                    Divider()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ApprovalRow: View {
    let item: ApprovalItem
    let onAction: (ApprovalAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.agentID)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.18), in: Capsule())
                Spacer()
                Text(item.detectedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(item.prompt)
                .font(.body)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button("Approve") { onAction(.approve) }
                Button("Approve all") { onAction(.approveAll) }
                Button("Deny", role: .destructive) { onAction(.deny) }
            }
            .controlSize(.small)
            .disabled(item.state != .pending)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
