// ApprovalInboxTests — routing, state transitions, input sink delivery.

import Foundation
import XCTest

@testable import HangarCore

/// Sendable container that lets the @Sendable input sink record writes
/// without needing var capture in a concurrently-executing closure.
private final class WriteLog: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [(UUID, String)] = []

    func append(_ paneID: UUID, _ text: String) {
        lock.lock()
        entries.append((paneID, text))
        lock.unlock()
    }

    func snapshot() -> [(UUID, String)] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }
}

final class ApprovalInboxTests: XCTestCase {
    func testAddThenRespondApproveSendsYes() async {
        let log = WriteLog()
        let inbox = ApprovalInbox { paneID, text in log.append(paneID, text) }
        let paneID = UUID()
        let item = ApprovalItem(paneID: paneID, agentID: "claude_code", prompt: "Run rm?")
        await inbox.add(item)
        await inbox.respond(itemID: item.id, action: .approve)

        let count = await inbox.items.count
        XCTAssertEqual(count, 1)
        let state = await inbox.items.first?.state
        XCTAssertEqual(state, .approved)
        let written = log.snapshot()
        XCTAssertEqual(written.count, 1)
        XCTAssertEqual(written.first?.0, paneID)
        XCTAssertEqual(written.first?.1, "y\n")
    }

    func testDenySendsN() async {
        let log = WriteLog()
        let inbox = ApprovalInbox { paneID, text in log.append(paneID, text) }
        let item = ApprovalItem(paneID: UUID(), agentID: "codex", prompt: "Apply patch?")
        await inbox.add(item)
        await inbox.respond(itemID: item.id, action: .deny)
        XCTAssertEqual(log.snapshot().map { $0.1 }, ["n\n"])
    }

    func testApproveAllSendsA() async {
        let log = WriteLog()
        let inbox = ApprovalInbox { paneID, text in log.append(paneID, text) }
        let item = ApprovalItem(paneID: UUID(), agentID: "hermes", prompt: "Continue?")
        await inbox.add(item)
        await inbox.respond(itemID: item.id, action: .approveAll)
        XCTAssertEqual(log.snapshot().map { $0.1 }, ["a\n"])
        let state = await inbox.items.first?.state
        XCTAssertEqual(state, .approvedAll)
    }

    func testPendingCountIgnoresResolved() async {
        let inbox = ApprovalInbox()
        let one = ApprovalItem(paneID: UUID(), agentID: "claude_code", prompt: "?")
        let two = ApprovalItem(paneID: UUID(), agentID: "codex", prompt: "?")
        await inbox.add(one)
        await inbox.add(two)
        await inbox.respond(itemID: one.id, action: .approve)
        let pending = await inbox.pendingCount()
        XCTAssertEqual(pending, 1)
    }

    func testMultiPaneRoutingIndependent() async {
        let log = WriteLog()
        let inbox = ApprovalInbox { paneID, text in log.append(paneID, text) }
        let paneA = UUID()
        let paneB = UUID()
        let itemA = ApprovalItem(paneID: paneA, agentID: "claude_code", prompt: "?")
        let itemB = ApprovalItem(paneID: paneB, agentID: "codex", prompt: "?")
        await inbox.add(itemA)
        await inbox.add(itemB)
        await inbox.respond(itemID: itemA.id, action: .approve)
        await inbox.respond(itemID: itemB.id, action: .deny)
        let written = log.snapshot()
        XCTAssertEqual(written.count, 2)
        XCTAssertTrue(written.contains { $0.0 == paneA && $0.1 == "y\n" })
        XCTAssertTrue(written.contains { $0.0 == paneB && $0.1 == "n\n" })
    }
}
