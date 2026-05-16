// ThemeTests — builtins exist + ThemeStore switching works.

import XCTest

@testable import HangarKit

@MainActor
final class ThemeTests: XCTestCase {
    func testBuiltinsContainDarkAndLight() {
        XCTAssertEqual(Theme.builtins.count, 2)
        XCTAssertNotNil(Theme.builtin(id: "hangar-dark"))
        XCTAssertNotNil(Theme.builtin(id: "hangar-light"))
        XCTAssertNil(Theme.builtin(id: "nonexistent"))
    }

    func testThemeStoreDefaultsToDark() {
        let store = ThemeStore()
        XCTAssertEqual(store.current.id, "hangar-dark")
    }

    func testThemeStoreResolvesByID() {
        let store = ThemeStore()
        store.resolve(themeID: "hangar-light")
        XCTAssertEqual(store.current.id, "hangar-light")
    }

    func testUnknownIDLeavesCurrentUntouched() {
        let store = ThemeStore(initial: .hangarLight)
        store.resolve(themeID: "no-such-theme")
        XCTAssertEqual(store.current.id, "hangar-light")
    }
}
