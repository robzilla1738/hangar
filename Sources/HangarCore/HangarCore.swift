// HangarCore — non-UI building blocks for Hangar.
// © 2026 Robert Courson and Hangar contributors. MIT License.

import Foundation

/// Public namespace for HangarCore-level facts.
///
/// Holds version and build metadata reflected in the About panel and the cost pill tooltip.
public enum HangarCore {
    /// Marketing version string.
    ///
    /// Reflected in the cost pill tooltip and the About panel.
    public static let version = "0.1.1"

    /// Build identifier baked into binaries.
    ///
    /// Refined in Phase 13 from CI.
    public static let buildIdentifier = "v0.1.1"
}
