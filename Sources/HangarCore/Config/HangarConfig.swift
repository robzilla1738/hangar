// HangarConfig — typed schema for ~/.config/hangar/config.json5.
// Codable + Sendable. Defaults baked into each section's `init`. JSON5
// parsing (comments + trailing commas) is handled by `ConfigStore` via
// JSONSerialization with .json5 option (available macOS 13+).

import Foundation

/// Top-level Hangar configuration mirrored from ~/.config/hangar/config.json5.
public struct HangarConfig: Codable, Sendable, Equatable {
    public var general: GeneralSection
    public var appearance: AppearanceSection
    public var fonts: FontsSection
    public var agents: AgentsSection
    public var keybindings: KeybindingsSection
    public var costs: CostsSection
    public var worktree: WorktreeSection
    public var experimental: ExperimentalSection

    public init(
        general: GeneralSection = GeneralSection(),
        appearance: AppearanceSection = AppearanceSection(),
        fonts: FontsSection = FontsSection(),
        agents: AgentsSection = AgentsSection(),
        keybindings: KeybindingsSection = KeybindingsSection(),
        costs: CostsSection = CostsSection(),
        worktree: WorktreeSection = WorktreeSection(),
        experimental: ExperimentalSection = ExperimentalSection()
    ) {
        self.general = general
        self.appearance = appearance
        self.fonts = fonts
        self.agents = agents
        self.keybindings = keybindings
        self.costs = costs
        self.worktree = worktree
        self.experimental = experimental
    }

    /// Factory-default config, baked into the binary.
    public static let defaults = HangarConfig()
}

// MARK: - Sections

public struct GeneralSection: Codable, Sendable, Equatable {
    public enum Startup: String, Codable, Sendable {
        case newWindow = "new_window"
        case restoreLast = "restore_last"
    }

    public var startup: Startup

    public init(startup: Startup = .newWindow) {
        self.startup = startup
    }
}

public struct AppearanceSection: Codable, Sendable, Equatable {
    public enum TitlebarStyle: String, Codable, Sendable {
        case unified
        case inset
    }

    public var theme: String
    public var transparency: Double
    public var titlebarStyle: TitlebarStyle

    enum CodingKeys: String, CodingKey {
        case theme
        case transparency
        case titlebarStyle = "titlebar_style"
    }

    public init(
        theme: String = "hangar-dark",
        transparency: Double = 0.05,
        titlebarStyle: TitlebarStyle = .unified
    ) {
        self.theme = theme
        self.transparency = transparency
        self.titlebarStyle = titlebarStyle
    }
}

public struct FontsSection: Codable, Sendable, Equatable {
    public var family: String
    public var size: Int
    public var lineHeight: Double

    enum CodingKeys: String, CodingKey {
        case family
        case size
        case lineHeight = "line_height"
    }

    public init(
        family: String = "SF Mono",
        size: Int = 13,
        lineHeight: Double = 1.2
    ) {
        self.family = family
        self.size = size
        self.lineHeight = lineHeight
    }
}

public struct AgentsSection: Codable, Sendable, Equatable {
    public struct Detector: Codable, Sendable, Equatable {
        public var binary: String
        public init(binary: String) { self.binary = binary }
    }

    public struct ExtraAgent: Codable, Sendable, Equatable {
        public var name: String
        public var binary: String
        public var profile: String

        public init(name: String, binary: String, profile: String) {
            self.name = name
            self.binary = binary
            self.profile = profile
        }
    }

    public var claudeCode: Detector
    public var codex: Detector
    public var hermes: Detector
    public var extra: [ExtraAgent]

    enum CodingKeys: String, CodingKey {
        case claudeCode = "claude_code"
        case codex
        case hermes
        case extra
    }

    public init(
        claudeCode: Detector = Detector(binary: "claude"),
        codex: Detector = Detector(binary: "codex"),
        hermes: Detector = Detector(binary: "hermes"),
        extra: [ExtraAgent] = []
    ) {
        self.claudeCode = claudeCode
        self.codex = codex
        self.hermes = hermes
        self.extra = extra
    }
}

public struct KeybindingsSection: Codable, Sendable, Equatable {
    public var missionControl: String
    public var approvalInbox: String
    public var newWorktree: String

    enum CodingKeys: String, CodingKey {
        case missionControl = "mission_control"
        case approvalInbox = "approval_inbox"
        case newWorktree = "new_worktree"
    }

    public init(
        missionControl: String = "cmd+0",
        approvalInbox: String = "cmd+shift+a",
        newWorktree: String = "cmd+shift+w"
    ) {
        self.missionControl = missionControl
        self.approvalInbox = approvalInbox
        self.newWorktree = newWorktree
    }
}

public struct CostsSection: Codable, Sendable, Equatable {
    public var warnAtUSD: Double
    public var hardStopAtUSD: Double?

    enum CodingKeys: String, CodingKey {
        case warnAtUSD = "warn_at_usd"
        case hardStopAtUSD = "hard_stop_at_usd"
    }

    public init(warnAtUSD: Double = 20.0, hardStopAtUSD: Double? = nil) {
        self.warnAtUSD = warnAtUSD
        self.hardStopAtUSD = hardStopAtUSD
    }
}

public struct WorktreeSection: Codable, Sendable, Equatable {
    public var baseDir: String

    enum CodingKeys: String, CodingKey {
        case baseDir = "base_dir"
    }

    public init(baseDir: String = "~/Hangar/Worktrees") {
        self.baseDir = baseDir
    }
}

public struct ExperimentalSection: Codable, Sendable, Equatable {
    public var useLibghostty: Bool

    enum CodingKeys: String, CodingKey {
        case useLibghostty = "use_libghostty"
    }

    public init(useLibghostty: Bool = false) {
        self.useLibghostty = useLibghostty
    }
}
