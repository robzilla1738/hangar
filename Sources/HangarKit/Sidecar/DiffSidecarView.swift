// DiffSidecarView — right-side panel listing files touched by agents.

import HangarCore
import SwiftUI

public struct DiffSidecarView: View {
    private let diffs: [Diff]
    private let onSelect: (Diff) -> Void

    public init(diffs: [Diff], onSelect: @escaping (Diff) -> Void) {
        self.diffs = diffs
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if diffs.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .frame(minWidth: 280)
    }

    private var header: some View {
        HStack {
            Text("Diff")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(diffs.count) file(s)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.text.below.ecg")
                .foregroundStyle(.secondary)
            Text("No file changes in this project.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(diffs.enumerated()), id: \.offset) { _, diff in
                    Button {
                        onSelect(diff)
                    } label: {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(diff.path.lastPathComponent)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                Text(diff.path.deletingLastPathComponent().path)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Text("+\(diff.totalAdditions)")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                Text("-\(diff.totalRemovals)")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
    }
}
