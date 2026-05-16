// AgentRegistry — holds the built-in profiles plus any registered custom ones,
// and resolves a binary name to a profile. Used by AgentDetector and the UI
// model-badge logic.

import Foundation

@MainActor
public final class AgentRegistry {
    public static let shared = AgentRegistry()

    private(set) var profiles: [AgentProfile]
    private let fallback: AgentProfile

    public init(extraProfiles: [AgentProfile] = []) {
        var builtins: [AgentProfile] = [
            ClaudeCodeProfile(),
            CodexProfile(),
            HermesProfile(),
        ]
        builtins.append(contentsOf: extraProfiles)
        self.profiles = builtins
        self.fallback = RawShellProfile()
    }

    /// Resolve a binary name (e.g. "claude") to a profile.
    ///
    /// Falls back to RawShellProfile when no built-in matches.
    public func resolve(binaryName: String) -> AgentProfile {
        let normalized = (binaryName as NSString).lastPathComponent
        for profile in profiles where profile.defaultBinaryNames.contains(normalized) {
            return profile
        }
        return fallback
    }

    /// Register an additional profile (e.g. user's `agents.extra` config).
    public func register(_ profile: AgentProfile) {
        profiles.append(profile)
    }
}
