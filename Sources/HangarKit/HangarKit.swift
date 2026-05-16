// HangarKit — SwiftUI components, layout, and theme primitives.
// © 2026 Robert Courson and Hangar contributors. MIT License.

import HangarCore
import SwiftUI

/// Public namespace for HangarKit-level identifiers.
public enum HangarKit {
    /// HangarKit version tracks HangarCore.
    public static var version: String { HangarCore.version }
}

/// Background surface used by the placeholder content view.
///
/// Replaced by the full Liquid Glass theme system in Phase 11.
public struct BackgroundSurface: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .controlBackgroundColor),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
