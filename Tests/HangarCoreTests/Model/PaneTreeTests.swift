// PaneTreeTests — split/replace/remove invariants on the recursive PaneNode tree.

import Foundation
import XCTest

@testable import HangarCore

final class PaneTreeTests: XCTestCase {
    func testLeafCountsAsOnePane() {
        let id = UUID()
        let node = PaneNode.pane(id: id)
        XCTAssertEqual(node.paneCount, 1)
        XCTAssertEqual(node.paneIDs, [id])
    }

    func testSplittingLeafProducesTwoChildren() {
        let original = UUID()
        let added = UUID()
        let node = PaneNode.pane(id: original)
            .splitting(paneID: original, adding: added, orientation: .horizontal)

        XCTAssertEqual(node.paneCount, 2)
        XCTAssertEqual(node.paneIDs, [original, added])

        if case .split(_, let orientation, let ratio, let children) = node {
            XCTAssertEqual(orientation, .horizontal)
            XCTAssertEqual(ratio, 0.5)
            XCTAssertEqual(children.count, 2)
        } else {
            XCTFail("Expected a split node")
        }
    }

    func testNestedSplitsPreserveOtherPanes() {
        let paneA = UUID()
        let paneB = UUID()
        let paneC = UUID()
        let tree = PaneNode.pane(id: paneA)
            .splitting(paneID: paneA, adding: paneB, orientation: .horizontal)
            .splitting(paneID: paneB, adding: paneC, orientation: .vertical)

        XCTAssertEqual(tree.paneCount, 3)
        XCTAssertEqual(Set(tree.paneIDs), Set([paneA, paneB, paneC]))
    }

    func testRemovingMiddlePaneCollapsesParent() {
        let paneA = UUID()
        let paneB = UUID()
        let paneC = UUID()
        let tree = PaneNode.pane(id: paneA)
            .splitting(paneID: paneA, adding: paneB, orientation: .horizontal)
            .splitting(paneID: paneB, adding: paneC, orientation: .vertical)

        guard let pruned = tree.removing(paneID: paneC) else {
            XCTFail("Tree should still have panes after removing one")
            return
        }
        XCTAssertEqual(pruned.paneCount, 2)
        XCTAssertEqual(Set(pruned.paneIDs), Set([paneA, paneB]))
    }

    func testRemovingLastPaneReturnsNil() {
        let id = UUID()
        let node = PaneNode.pane(id: id)
        XCTAssertNil(node.removing(paneID: id))
    }

    func testRoundTripCodable() throws {
        let paneA = UUID()
        let paneB = UUID()
        let tree = PaneNode.pane(id: paneA)
            .splitting(paneID: paneA, adding: paneB, orientation: .vertical)

        let data = try JSONEncoder().encode(tree)
        let decoded = try JSONDecoder().decode(PaneNode.self, from: data)
        XCTAssertEqual(tree, decoded)
    }

    func testTabSinglePaneHelper() {
        let tab = Tab.singlePane(title: "Test")
        XCTAssertEqual(tab.title, "Test")
        XCTAssertEqual(tab.root.paneCount, 1)
        XCTAssertEqual(tab.root.paneIDs.first, tab.activePaneID)
    }

    func testWindowSnapshotPicksFirstTabActive() {
        let tab1 = Tab.singlePane()
        let tab2 = Tab.singlePane()
        let snapshot = WindowSnapshot(tabs: [tab1, tab2])
        XCTAssertEqual(snapshot.activeTabID, tab1.id)
    }
}
