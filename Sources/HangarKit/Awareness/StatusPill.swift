// StatusPill — small SwiftUI pill rendering an agent's high-level status.
// Phase 11 will dress this in Liquid Glass and add animated transitions.

import HangarCore
import SwiftUI

public struct StatusPill: View {
    private let status: AgentStatus
    private let agentName: String?

    public init(status: AgentStatus, agentName: String? = nil) {
        self.status = status
        self.agentName = agentName
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.thinMaterial)
        )
        .accessibilityLabel(Text(accessibility))
    }

    private var color: Color {
        switch status {
        case .idle: return .gray
        case .thinking: return .blue
        case .runningTool: return .cyan
        case .awaitingApproval: return .yellow
        case .errored: return .red
        case .done: return .green
        }
    }

    private var label: String {
        switch status {
        case .idle: return "Idle"
        case .thinking: return "Thinking"
        case .runningTool: return "Running tool"
        case .awaitingApproval: return "Awaiting approval"
        case .errored: return "Errored"
        case .done: return "Done"
        }
    }

    private var accessibility: String {
        if let agentName {
            return "\(agentName) status: \(label)"
        }
        return "Agent status: \(label)"
    }
}
