// WindowOverlayBarTests — smoke that the overlay constructs across states.

import HangarCore
import SwiftUI
import XCTest

@testable import HangarKit

@MainActor
final class WindowOverlayBarTests: XCTestCase {
    func testConstructsWithNoCwdAndNoPane() {
        _ = WindowOverlayBar(
            cwdPath: nil,
            activePane: nil,
            pendingApprovalCount: 0
        )
    }

    func testConstructsWithCwdAndPendingBell() {
        _ = WindowOverlayBar(
            cwdPath: "/Users/robert/Code/terminal",
            activePane: nil,
            pendingApprovalCount: 3
        )
    }
}
