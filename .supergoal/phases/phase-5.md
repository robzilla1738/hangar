SUPERGOAL_PHASE_START
Phase: 5 of 9 — E · Mission Control (Cmd-0)
Task: Bind Cmd-0 (also the Mission Control button in WindowOverlayBar) to open a borderless overlay window above the frontmost Hangar window. The overlay aggregates AgentTileSnapshot from every PaneViewModel across every registered window. Clicking a tile focuses that pane in that window.
Type: brownfield, ui, integration
Mandatory commands: swift test, xcodebuild build, xcodebuild test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 8
Evidence required: build/test/lint clean; screenshot of Mission Control overlay open with at least 1 tile; tile-click brings the correct pane to front (manually verified, recorded in log)
Depends on phases: 1, 2

## Why

The visual headline of the product. Cmd-0 takes a multi-agent workflow from chaos to one glance.

## Work

- Add `Sources/HangarKit/MissionControl/MissionControlPresenter.swift`:
  - `@MainActor` class owning a borderless `NSWindow` (styleMask `[.borderless]`, level `.modalPanel`, content size = main screen visibleFrame)
  - `func present(snapshots: [AgentTileSnapshot], onSelect:)` shows the window with `MissionControlOverlay` as content
  - `func dismiss()` orders out
  - Esc / click-outside / Cmd-0 again dismiss

- Extend AppState with:
  - `var missionControlPresented: Bool = false`
  - `func toggleMissionControl()` — collects snapshots from all openWindows' panes and shows/hides
  - `func snapshotAllPanes() -> [AgentTileSnapshot]` — iterates registry

- Cmd-0 binding via SwiftUI Command in HangarApp:
  - `Button("Mission Control") { appState.toggleMissionControl() }.keyboardShortcut("0", modifiers: [.command])`

- Mission Control button in WindowOverlayBar (already there from phase B) now calls `appState.toggleMissionControl()` instead of a stub

- Click handler in `MissionControlOverlay.onSelect`:
  - Receives an AgentTileSnapshot
  - Look up the WindowViewModel in AppState.openWindows by tile.windowID
  - Find the NSWindow hosting it; `window.makeKeyAndOrderFront(nil)`; `window.makeFirstResponder(paneVM.emulator.view)`
  - Dismiss Mission Control

- Tests under `Tests/HangarKitTests/MissionControl/`:
  - `AgentTileAggregatorTests` (existing MissionControlSorterTests stays) — new test fixturing 2 fake windows × 3 panes each → snapshot aggregation returns 6 tiles sorted attention-first

## Acceptance criteria

- MissionControlPresenter.swift exists and manages an NSWindow with the documented behavior
- Cmd-0 toggles the overlay; pressing Cmd-0 again dismisses
- Esc dismisses
- Click-outside dismisses (within ~10pt margin)
- Snapshots reflect real PaneViewModels (with live status from phase A)
- Click-tile focuses the correct pane (verified by emitting a log line `MISSION_CONTROL_FOCUS: window=<id> pane=<id>` and asserting that pane.hasFocus becomes true)
- AgentTileAggregatorTests passes
- Build/test/lint exit 0; smoke screenshot at `.supergoal/evidence/phase-5-mission-control.png`

## Mandatory commands

- `swift test`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `/opt/homebrew/bin/swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required

- File listing of new files
- Test runner output naming AgentTileAggregatorTests
- Smoke screenshot
- A 1-paragraph note in the phase log confirming Cmd-0 cycle (open → close) works in the running app

## Notes

- The Mission Control overlay window should NOT be a separate Scene in SwiftUI — too much fight with menu bar and `key` semantics. AppKit `NSWindow` instance owned by AppState is cleaner.
- `collectionBehavior` should include `.canJoinAllSpaces, .stationary, .ignoresCycle` so Mission Control feels overlay-like.
