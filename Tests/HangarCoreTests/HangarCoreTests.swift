// HangarCoreTests — module bootstrap tests.

import XCTest

@testable import HangarCore

final class HangarCoreTests: XCTestCase {
    func testVersionIsNonEmpty() {
        XCTAssertFalse(HangarCore.version.isEmpty, "HangarCore.version must be a non-empty string")
    }

    func testBuildIdentifierIsNonEmpty() {
        XCTAssertFalse(
            HangarCore.buildIdentifier.isEmpty,
            "HangarCore.buildIdentifier must be a non-empty string"
        )
    }
}
