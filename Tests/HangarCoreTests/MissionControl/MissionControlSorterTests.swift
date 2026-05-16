// MissionControlSorterTests — attention-first ordering, then status priority.

import Foundation
import XCTest

@testable import HangarCore

final class MissionControlSorterTests: XCTestCase {
    private func snapshot(
        status: AgentStatus,
        needsAttention: Bool = false,
        name: String = "Agent"
    ) -> AgentTileSnapshot {
        AgentTileSnapshot(
            paneID: UUID(),
            windowID: UUID(),
            agentDisplayName: name,
            agentID: "any",
            model: nil,
            status: status,
            lastLines: [],
            needsAttention: needsAttention
        )
    }

    func testAttentionTilesComeFirst() {
        let sorted = MissionControlSorter.sort([
            snapshot(status: .idle, needsAttention: false, name: "A"),
            snapshot(status: .idle, needsAttention: true, name: "B"),
        ])
        XCTAssertEqual(sorted.first?.agentDisplayName, "B")
    }

    func testStatusPriorityOrder() {
        let sorted = MissionControlSorter.sort([
            snapshot(status: .idle, name: "idle"),
            snapshot(status: .thinking, name: "thinking"),
            snapshot(status: .errored, name: "errored"),
            snapshot(status: .awaitingApproval, name: "awaiting"),
            snapshot(status: .runningTool, name: "running"),
            snapshot(status: .done, name: "done"),
        ])
        XCTAssertEqual(
            sorted.map { $0.agentDisplayName },
            ["awaiting", "errored", "running", "thinking", "done", "idle"]
        )
    }

    func testAttentionBeatsStatusPriority() {
        // An idle pane that needs attention sorts ahead of an awaiting pane
        // that doesn't (rare, but the rule is documented).
        let sorted = MissionControlSorter.sort([
            snapshot(status: .awaitingApproval, needsAttention: false, name: "no-attn"),
            snapshot(status: .idle, needsAttention: true, name: "attn"),
        ])
        XCTAssertEqual(sorted.first?.agentDisplayName, "attn")
    }
}
