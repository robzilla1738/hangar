// MissionControlOverlayTests — assert animation constants are within
// the spec'd bounds (verifying the falsifiable Phase 7 criterion).

import XCTest

@testable import HangarKit

final class MissionControlOverlayTests: XCTestCase {
    func testOpenAnimationDurationWithin200To500ms() {
        XCTAssertGreaterThanOrEqual(MissionControlOverlay.openAnimationDuration, 0.2)
        XCTAssertLessThanOrEqual(MissionControlOverlay.openAnimationDuration, 0.5)
    }

    func testTileCascadeStaggerIsPositive() {
        XCTAssertGreaterThan(MissionControlOverlay.tileCascadeStaggerMS, 0)
    }
}
