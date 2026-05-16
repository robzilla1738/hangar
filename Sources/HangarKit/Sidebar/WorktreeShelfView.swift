// WorktreeShelfView — sidebar section listing live worktrees.

import HangarCore
import SwiftUI

public struct WorktreeShelfView: View {
    private let worktrees: [Worktree]
    private let onSelect: (Worktree) -> Void
    private let onCreate: () -> Void

    public init(
        worktrees: [Worktree],
        onSelect: @escaping (Worktree) -> Void,
        onCreate: @escaping () -> Void
    ) {
        self.worktrees = worktrees
        self.onSelect = onSelect
        self.onCreate = onCreate
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Worktrees")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onCreate) {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("New worktree (⌘⇧W)")
            }
            if worktrees.isEmpty {
                Text("No worktrees yet — ⌘⇧W to create one.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(worktrees) { worktree in
                    WorktreeRow(worktree: worktree) { onSelect(worktree) }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private struct WorktreeRow: View {
    let worktree: Worktree
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.branch")
                    .font(.caption)
                Text(worktree.branch)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                Spacer()
                if worktree.isDirty {
                    Circle()
                        .fill(.yellow)
                        .frame(width: 6, height: 6)
                }
                if worktree.aheadCount > 0 {
                    Text("↑\(worktree.aheadCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if worktree.behindCount > 0 {
                    Text("↓\(worktree.behindCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Worktree \(worktree.branch)" + (worktree.isDirty ? ", dirty" : "")
        )
    }
}
