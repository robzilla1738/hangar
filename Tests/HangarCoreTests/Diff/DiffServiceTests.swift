// DiffServiceTests — empty / new file / modified.

import Foundation
import XCTest

@testable import HangarCore

final class DiffServiceTests: XCTestCase {
    private let path = URL(fileURLWithPath: "/tmp/example.swift")

    func testUnchangedReturnsEmptyDiff() {
        let diff = DiffService.compare(baseline: "a\nb\nc", current: "a\nb\nc", path: path)
        XCTAssertTrue(diff.isEmpty)
    }

    func testNewFileShowsAllAdditions() {
        let diff = DiffService.compare(baseline: "", current: "first\nsecond\nthird", path: path)
        XCTAssertFalse(diff.isEmpty)
        XCTAssertGreaterThan(diff.totalAdditions, 0)
    }

    func testModifiedLineShowsOneAddOneRemove() {
        let diff = DiffService.compare(baseline: "a\nold\nc", current: "a\nnew\nc", path: path)
        XCTAssertEqual(diff.totalAdditions, 1)
        XCTAssertEqual(diff.totalRemovals, 1)
    }

    func testInsertionAddsLine() {
        let diff = DiffService.compare(baseline: "a\nc", current: "a\nb\nc", path: path)
        XCTAssertEqual(diff.totalAdditions, 1)
        XCTAssertEqual(diff.totalRemovals, 0)
    }
}
