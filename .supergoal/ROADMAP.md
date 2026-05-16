# Roadmap: Hangar v0.2.0 — visible agent orchestration

**Task:** Wire every existing HangarCore/HangarKit type into the visible UI so opening Hangar and typing `claude`/`codex`/`hermes` produces a visibly different experience from any other terminal — model badge, status pill, approval bell + macOS notification, cost pill, Mission Control, sidebar, sidecar.
**Type:** brownfield, ui, integration
**Created:** 2026-05-16
**Total phases:** 9

## Context summary

- **Stack:** Swift 6.2 strict concurrency · SwiftUI + AppKit · SwiftTerm 1.13 · GRDB 7 · Sparkle 2 · Xcode 26.3 · macOS 15 deployment target (Liquid Glass features `@available(macOS 26, *)`-gated)
- **Repo state:** v0.1.1 shipped (commit 0019939); GitHub release live; Homebrew tap live
- **Build / test / lint commands:**
  - `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
  - `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
  - `swift test`
  - `swiftlint --strict`
  - `/opt/homebrew/bin/swift-format lint --recursive --strict Sources Tests Hangar`
- **Risky areas:** SwiftUI toolbar vs transparent NSWindow chrome; agent detection from PTY output without OSC 133; screencapture automation

## Assumptions

- v0.1.1 chrome (transparent title bar, dark window background) stays; the new title-bar overlay is a custom `WindowOverlayBar` view at the top of the content area, not a SwiftUI `.toolbar`
- Agent detection uses a `ShellCommandDetector` (regex over `% command` / `$ command` lines) plus the existing `AgentRegistry.resolve(binaryName:)`. OSC 133 shell-integration is documented as a v0.3 upgrade.
- `screencapture -l <window-id>` (window-id from `osascript -e 'tell app "Hangar" to id of window 1'`) is the preferred smoke-capture mechanism; full-screen fallback if Accessibility is denied.
- AppState gains a shared `ApprovalInbox`, `CostLedger`, plus an `openWindows: [WindowViewModel]` registry that windows register/unregister on appear/disappear.
- `PaneInputSink` returned to the inbox writes to the originating emulator's PTY via a callback held by the registry.
- Mission Control opens as a borderless `NSWindow` (modal panel level) over whatever's frontmost.
- Sidebar/sidecar wrap the existing `WindowRootView` in an `HStack(LeftSidebar, RootPaneTree, RightSidecar)` with collapse state on `WindowViewModel`.
- v0.2.0 versioning: bump `MARKETING_VERSION` to `0.2.0`; tag `v0.2.0`; cask SHA-256 from the new notarized DMG.

## Risk top 3

1. **SwiftUI toolbar vs transparent NSWindow** — likelihood high, mitigation: ship a custom in-content overlay row; don't touch SwiftUI `.toolbar`.
2. **Agent detection misses commands** — likelihood medium, mitigation: per-shell regex set with conservative defaults; manual model badge override via UI (deferred to v0.3) noted; ShellCommandDetector tested against zsh+bash+fish prompt formats.
3. **Smoke screenshots flaky** — likelihood medium, mitigation: capture via NSWindow ID; fall back to full-screen with `-x`; treat blank/wrong-app screenshots as a phase failure and retry per 3-strike.

## Phase map

| # | Phase | Depends on | Deliverable |
|---|-------|------------|-------------|
| A | Output wiring + ShellCommandDetector | — | PaneViewModel observes outputStream, feeds parser, publishes detectedAgentID + status; agent badge appears when `claude` runs in a pane |
| B | Title-bar overlay + AppState registry | A | Custom `WindowOverlayBar` at top of content view showing pane title + model badge (left) + StatusPill (center) + CostPill + ApprovalBell + Mission Control button (right) |
| C | Approval routing end-to-end | A, B | Approval prompts route to a shared ApprovalInbox; bell badge updates; macOS notification fires; Cmd-Shift-A opens popover; Approve writes `y\n` |
| D | Cost wiring | A, B | Token-usage regex per profile; PaneViewModel forwards events to AppState.costLedger; CostPill increments live |
| E | Mission Control (Cmd-0) | A, B | Cmd-0 opens borderless overlay window listing every PaneViewModel across windows; click tile → focus that pane |
| F | Left sidebar (projects + worktrees) | B | Sidebar wraps content; Cmd-Shift-S toggle; WorktreeShelfView lists current repo's worktrees; Cmd-Shift-W opens new-worktree sheet |
| G | Right sidecar (diff) | B, F | Right-edge collapsible sidecar wired to FSEventsWatcher on project root; Cmd-Option-D toggle; edits in cwd appear as diff rows |
| H | Terminal table-stakes | A | Native tabs (Cmd-T), font sizing (Cmd-=/Cmd--), find (Cmd-F), clear (Cmd-K), URL Cmd-click, drag-folder-to-paste, restore-last-state |
| I | Polish + ship v0.2.0 | A-H | MARKETING_VERSION bump, CHANGELOG, archive+sign+notarize+staple .app+DMG, tag v0.2.0, GitHub release, cask bump to 0.2.0 |

---

(Detailed phase specs live at `.supergoal/phases/phase-1.md` through `.supergoal/phases/phase-9.md`.)
