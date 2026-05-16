// HangarKitTests — module bootstrap tests.

import XCTest

@testable import HangarKit

@MainActor
final class HangarKitTests: XCTestCase {
    func testVersionMatchesCore() {
        XCTAssertEqual(HangarKit.version, "0.1.0-dev", "HangarKit.version should track HangarCore.version")
    }

    func testBackgroundSurfaceConstructs() {
        // Smoke test: instantiating a view should not crash.
        _ = BackgroundSurface()
    }
}
