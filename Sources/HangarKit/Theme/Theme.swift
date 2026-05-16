// Theme — token bundle consumed by every Hangar surface.
// Two built-ins ship in v0.1: Hangar Dark, Hangar Light. The Liquid Glass
// material surfaces are picked up from SwiftUI's materials directly.

import SwiftUI

public struct Theme: Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let appearance: ColorScheme

    public let chromeBackground: Color
    public let paneBackground: Color
    public let paneForeground: Color
    public let accent: Color
    public let divider: Color
    public let focusRing: Color
    public let statusIdle: Color
    public let statusThinking: Color
    public let statusAwaiting: Color
    public let statusErrored: Color
    public let statusDone: Color
    public let attentionDot: Color
    public let pillBackground: Color
    public let pillForeground: Color

    public init(
        id: String,
        displayName: String,
        appearance: ColorScheme,
        chromeBackground: Color,
        paneBackground: Color,
        paneForeground: Color,
        accent: Color,
        divider: Color,
        focusRing: Color,
        statusIdle: Color,
        statusThinking: Color,
        statusAwaiting: Color,
        statusErrored: Color,
        statusDone: Color,
        attentionDot: Color,
        pillBackground: Color,
        pillForeground: Color
    ) {
        self.id = id
        self.displayName = displayName
        self.appearance = appearance
        self.chromeBackground = chromeBackground
        self.paneBackground = paneBackground
        self.paneForeground = paneForeground
        self.accent = accent
        self.divider = divider
        self.focusRing = focusRing
        self.statusIdle = statusIdle
        self.statusThinking = statusThinking
        self.statusAwaiting = statusAwaiting
        self.statusErrored = statusErrored
        self.statusDone = statusDone
        self.attentionDot = attentionDot
        self.pillBackground = pillBackground
        self.pillForeground = pillForeground
    }

    public static let hangarDark = Theme(
        id: "hangar-dark",
        displayName: "Hangar Dark",
        appearance: .dark,
        chromeBackground: Color(red: 0.07, green: 0.07, blue: 0.09),
        paneBackground: Color(red: 0.05, green: 0.05, blue: 0.07),
        paneForeground: Color(red: 0.94, green: 0.94, blue: 0.95),
        accent: Color(red: 0.58, green: 0.51, blue: 0.85),
        divider: Color.white.opacity(0.08),
        focusRing: Color(red: 0.58, green: 0.51, blue: 0.85).opacity(0.75),
        statusIdle: Color(white: 0.55),
        statusThinking: Color.blue,
        statusAwaiting: Color.yellow,
        statusErrored: Color.red,
        statusDone: Color.green,
        attentionDot: Color.red,
        pillBackground: Color.white.opacity(0.12),
        pillForeground: Color(red: 0.95, green: 0.95, blue: 0.97)
    )

    public static let hangarLight = Theme(
        id: "hangar-light",
        displayName: "Hangar Light",
        appearance: .light,
        chromeBackground: Color(red: 0.97, green: 0.97, blue: 0.95),
        paneBackground: Color(red: 1.0, green: 1.0, blue: 0.99),
        paneForeground: Color(red: 0.08, green: 0.08, blue: 0.1),
        accent: Color(red: 0.16, green: 0.36, blue: 0.78),
        divider: Color.black.opacity(0.08),
        focusRing: Color(red: 0.16, green: 0.36, blue: 0.78).opacity(0.75),
        statusIdle: Color(white: 0.4),
        statusThinking: Color.blue,
        statusAwaiting: Color.orange,
        statusErrored: Color.red,
        statusDone: Color.green,
        attentionDot: Color.red,
        pillBackground: Color.black.opacity(0.06),
        pillForeground: Color(red: 0.08, green: 0.08, blue: 0.1)
    )

    public static let builtins: [Theme] = [hangarDark, hangarLight]

    public static func builtin(id: String) -> Theme? {
        builtins.first { $0.id == id }
    }
}

@MainActor
@Observable
public final class ThemeStore {
    public private(set) var current: Theme

    public init(initial: Theme = .hangarDark) {
        self.current = initial
    }

    public func apply(_ theme: Theme) {
        current = theme
    }

    public func resolve(themeID: String) {
        if let match = Theme.builtin(id: themeID) {
            current = match
        }
    }
}
