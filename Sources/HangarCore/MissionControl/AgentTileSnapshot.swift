// AgentTileSnapshot — value type rendered by each Mission Control tile.
// The view aggregator builds an array of these from all open windows.

import Foundation

public struct AgentTileSnapshot: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let paneID: UUID
    public let windowID: UUID
    public let agentDisplayName: String
    public let agentID: AgentProfileID
    public let model: String?
    public let status: AgentStatus
    public let lastLines: [String]
    public let tokensToday: Int
    public let needsAttention: Bool

    public init(
        id: UUID = UUID(),
        paneID: UUID,
        windowID: UUID,
        agentDisplayName: String,
        agentID: AgentProfileID,
        model: String?,
        status: AgentStatus,
        lastLines: [String],
        tokensToday: Int = 0,
        needsAttention: Bool = false
    ) {
        self.id = id
        self.paneID = paneID
        self.windowID = windowID
        self.agentDisplayName = agentDisplayName
        self.agentID = agentID
        self.model = model
        self.status = status
        self.lastLines = lastLines
        self.tokensToday = tokensToday
        self.needsAttention = needsAttention
    }
}

public enum MissionControlSorter {
    /// Attention-first, then by status priority, then by recency.
    public static func sort(_ snapshots: [AgentTileSnapshot]) -> [AgentTileSnapshot] {
        snapshots.sorted { lhs, rhs in
            if lhs.needsAttention != rhs.needsAttention {
                return lhs.needsAttention && !rhs.needsAttention
            }
            return priority(lhs.status) < priority(rhs.status)
        }
    }

    private static func priority(_ status: AgentStatus) -> Int {
        switch status {
        case .awaitingApproval: return 0
        case .errored: return 1
        case .runningTool: return 2
        case .thinking: return 3
        case .done: return 4
        case .idle: return 5
        }
    }
}
