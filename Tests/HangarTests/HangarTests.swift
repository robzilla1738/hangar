// HangarTests — app-target host tests.
// These run against the live Hangar.app bundle and can use AppState directly.

import HangarCore
import XCTest

@testable import Hangar

final class HangarTests: XCTestCase {
    @MainActor
    func testAppStateGreetingIncludesVersion() {
        let state = AppState()
        XCTAssertTrue(
            state.greeting.contains(HangarCore.version),
            "AppState.greeting should mention the HangarCore version"
        )
    }
}
