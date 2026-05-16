# THINKING — Hangar v0.2.0 (integration run)

## Goals
1. Make Hangar visibly different from any other terminal **on first launch**.
2. Every supporting type already in HangarCore/HangarKit becomes user-reachable.
3. Terminal table-stakes (tabs/font/find/clear/URL-click/drag) all work.
4. Shippable v0.2.0 release on GitHub + cask bump by end of run.

## Constraints
- Swift 6.2 strict concurrency
- macOS 15 minimum deployment target (Liquid Glass APIs `@available(macOS 26, *)`-gated)
- SwiftTerm 1.13 as the renderer
- No `trust-prior-verify` escape: every phase produces a smoke screenshot in `.supergoal/evidence/`
- v0.1.1 chrome (transparent title bar + dark window) stays; new title-bar overlay sits in the content view, not via SwiftUI `.toolbar` (which fights `titlebarAppearsTransparent`)

## Top 3 risks
1. **SwiftUI `.toolbar` vs custom transparent NSWindow chrome** — likely conflict. Mitigation: ship a custom `WindowOverlayBar` view at the top of the content view; ignore SwiftUI `.toolbar` entirely.
2. **Agent detection from PTY output is fuzzy** — without OSC 133, we can't be sure which token is the user's command. Mitigation: a `ShellCommandDetector` regex catches `(^|\n)(\$|%|❯|>) (\S+)` and feeds the captured binary name to AgentRegistry; conservative fallback is "no agent detected." Document the OSC 133 upgrade path for v0.3.
3. **Live screencapture flakiness** — capturing just the Hangar window requires Accessibility permission for AppleScript. Mitigation: use `osascript -e 'tell application "Hangar" to id of window 1'` to fetch the windowID, then `screencapture -l <id> -o file.png`. Per-phase smoke checks tolerate full-screen capture as fallback.

## Non-obvious dependencies
- Phase A (output wiring) gates B, C, D, E (every visible feature needs the state machine running)
- Phase B (chrome) provides the host for C/D/E indicators; ship first after A
- Phase E (Mission Control) requires AppState to track all open windows → that's added in B
- Phase H is logically independent of A-G but ordered after for ship hygiene
- Phase I (release) requires every prior phase green

## Memory hits applied
- v0.1.1 chrome quirks documented in `reference_macos_release_pipeline` (reuse exact incantation)
- Trailing-comma + swift-format/.swift-format gotchas → no new lint surprises (`reference_swift_format_config`)
- User's "Ghostty-grade" polish bar (user_professional_background)

## Tools/skills relied on
- `macos` skill: SwiftUI/AppKit window chrome
- `testing` skill: XCTest patterns for actor + async streams
- `release-review` skill: pre-tag review in Phase I
- Real `claude` / `codex` / `hermes` binaries: integration smoke at C/D/E

## Best practices applied
- Each phase's deliverables are checked into a screenshot file path under `.supergoal/evidence/`
- Per-phase commit (Conventional Commits) so v0.2.0 history reads cleanly
- Memory writeback: any non-obvious integration gotcha (e.g. NSWindow first-responder routing with sidebar) gets a `reference_*.md`
