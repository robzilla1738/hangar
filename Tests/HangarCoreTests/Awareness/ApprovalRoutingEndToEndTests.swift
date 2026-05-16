// ApprovalRoutingEndToEndTests — wire an ApprovalInbox into the
// AwarenessAdapter pattern and verify that the responded-to write
// reaches the originating pane sink.

import Foundation
import XCTest

@testable import HangarCore

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

final class ApprovalRoutingEndToEndTests: XCTestCase {
    func testReportAndRespondPath() async throws {
        let log = WriteLog()
        let inbox = ApprovalInbox { paneID, text in log.append(paneID, text) }

        let adapter = AwarenessAdapter(approvalInbox: inbox)
        let paneID = UUID()
        let item = ApprovalItem(paneID: paneID, agentID: "claude_code", prompt: "Run rm?")

        adapter.report(item, agentDisplayName: "Claude Code")
        // Let the adapter's Task drain
        try await Task.sleep(nanoseconds: 100_000_000)

        let items = await inbox.items
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, item.id)

        await inbox.respond(itemID: item.id, action: .approve)
        let written = log.snapshot()
        XCTAssertEqual(written.count, 1)
        XCTAssertEqual(written.first?.0, paneID)
        XCTAssertEqual(written.first?.1, "y\n")
    }

    func testDenyAndApproveAllRoutes() async throws {
        let log = WriteLog()
        let inbox = ApprovalInbox { paneID, text in log.append(paneID, text) }
        let adapter = AwarenessAdapter(approvalInbox: inbox)

        let denyItem = ApprovalItem(paneID: UUID(), agentID: "c", prompt: "?")
        let approveAllItem = ApprovalItem(paneID: UUID(), agentID: "d", prompt: "?")
        adapter.report(denyItem, agentDisplayName: nil)
        adapter.report(approveAllItem, agentDisplayName: nil)
        try await Task.sleep(nanoseconds: 100_000_000)

        await inbox.respond(itemID: denyItem.id, action: .deny)
        await inbox.respond(itemID: approveAllItem.id, action: .approveAll)

        let texts = log.snapshot().map { $0.1 }
        XCTAssertTrue(texts.contains("n\n"))
        XCTAssertTrue(texts.contains("a\n"))
    }
}
