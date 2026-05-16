// ProjectStoreTests — basic CRUD + recency ordering for the in-memory store.

import Foundation
import XCTest

@testable import HangarCore

final class ProjectStoreTests: XCTestCase {
    func testCreateAndList() async {
        let store = ProjectStore()
        let project = await store.create(name: "Hangar", cwd: URL(fileURLWithPath: "/tmp/hangar"))
        let all = await store.list()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, project.id)
        XCTAssertEqual(all.first?.name, "Hangar")
    }

    func testRecentSortsByLastOpened() async {
        let store = ProjectStore()
        var older = Project(name: "A", cwd: URL(fileURLWithPath: "/a"))
        older.lastOpenedAt = Date(timeIntervalSinceNow: -3600)
        var newer = Project(name: "B", cwd: URL(fileURLWithPath: "/b"))
        newer.lastOpenedAt = Date()
        await store.upsert(older)
        await store.upsert(newer)

        let recent = await store.recent(limit: 5)
        XCTAssertEqual(recent.first?.name, "B")
        XCTAssertEqual(recent.last?.name, "A")
    }

    func testDeleteRemoves() async {
        let store = ProjectStore()
        let project = await store.create(name: "X", cwd: URL(fileURLWithPath: "/x"))
        await store.delete(id: project.id)
        let all = await store.list()
        XCTAssertTrue(all.isEmpty)
    }

    func testTouchUpdatesLastOpened() async throws {
        let store = ProjectStore()
        let project = await store.create(name: "Y", cwd: URL(fileURLWithPath: "/y"))
        let original = project.lastOpenedAt
        try await Task.sleep(nanoseconds: 10_000_000)
        await store.touch(id: project.id)
        let fetched = await store.list().first
        XCTAssertNotNil(fetched)
        XCTAssertGreaterThan(fetched?.lastOpenedAt ?? .distantPast, original)
    }
}
