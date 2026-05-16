SUPERGOAL_PHASE_START
Phase: 7 of 13 — Mission Control grid
Task: Implement the Cmd-0 full-window overlay that displays every pane across every window as a tile (model badge, status pill, last 3 lines, attention dot), with click-to-focus animation that flies the user back to the chosen pane.
Type: greenfield, ui
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 10
Evidence required: build/test exit codes, screenshot of grid with 4+ panes, focus-fly animation manually confirmed
Depends on phases: 6

## Why

This is the visual headline of the product — the moment a user says "oh that's why I'd use this instead of iTerm." It must feel like Mission Control on macOS itself: smooth, layered, glanceable.

## Work

- Add `Sources/HangarKit/MissionControl/`:
  - `MissionControlOverlay` — full-screen SwiftUI view, presented over the current window via a separate `NSWindow` (style mask `.borderless`, level `.modalPanel`, opaque false, content rounded vibrancy)
  - `AgentTileView` — single tile: rounded card, model badge top-left, status pill top-right, last 3 lines of recent output (monospace, dimmed), attention dot bottom-right; hover lifts via subtle shadow + 2pt scale
  - `MissionControlViewModel` — aggregates `PaneViewModel`s from every window, sorts by attention first then by recency
- Trigger:
  - Cmd-0 in any Hangar window opens the overlay
  - Pressing Cmd-0 again, Escape, or clicking outside any tile closes it
- Tile content:
  - Model badge: provider color (Anthropic orange, OpenAI blue-green, Nous lavender, neutral gray)
  - Status pill: same component as Phase 6
  - Last 3 output lines: from the `TerminalEmulator.scrollback` API (add `recentLines(_ count: Int) -> [String]` if missing)
  - Attention dot: red 8pt when `currentStatus == .awaiting_approval || .errored`, else hidden
- Animation:
  - Open: tiles cascade in with a 50ms-staggered scale-from-0.96 + opacity-from-0
  - Click tile: tile expands to full screen + window flies to front + overlay dismisses (matched-geometry effect via `.matchedGeometryEffect`)
- Empty state: when no panes exist, display centered text "No active panes — open a window to get started" + a `New Window` button
- Tests under `Tests/HangarKitTests/MissionControl/`:
  - `MissionControlViewModelSortingTests` — feed a list of fake panes; assert "awaiting approval" sorts to front, then "errored", then "thinking", then "idle"; ties broken by recency
  - `MissionControlAggregationTests` — given 2 fake windows × 3 panes each, assert the VM enumerates all 6
  - Snapshot test (where stable) of `AgentTileView` for each status state via `swift-snapshot-testing` or simple PNG diff (`xcrun simctl` not available on macOS; use the macOS SwiftUI snapshot harness)

## Acceptance criteria (all must pass — verify each in transcript)

- Cmd-0 opens the Mission Control overlay above whatever window is frontmost
- Overlay closes on Cmd-0, Escape, or click-outside
- Each tile shows: model badge, status pill, last 3 output lines, attention dot when appropriate
- Tiles are sorted attention-first, then recency
- Empty state renders when no panes exist
- Clicking a tile focuses the originating window AND the originating pane (verified by checking which pane has the focus ring after click)
- Mission Control open animation duration is measurable via `MissionControlOverlay.openAnimationDuration` (unit test asserts 200ms ≤ duration ≤ 500ms); tile cascade stagger > 0ms (asserted in unit test)
- All Mission Control test classes pass
- Build / test / lint exit 0
- `Cmd-0` keybinding read from `config.keybindings.mission_control` (not hardcoded)

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of `Sources/HangarKit/MissionControl/` and `Tests/HangarKitTests/MissionControl/`
- Test runner output naming the two new test classes (+ snapshot tests if used)
- `.supergoal/evidence/phase-7-mission-control.png` — screenshot showing 4+ tiles, one in awaiting-approval state with red dot

## Notes

- Consult `macos` skill + `design` skill for matched-geometry transitions on macOS 26 (the API surface is mature in Tahoe).
- The overlay window needs to *not* steal the menu bar; use `.borderless` + correct `collectionBehavior` (`.canJoinAllSpaces, .stationary`).
- Tiles render small snapshots of pane state; do NOT keep live PTY streams attached for every tile — read once on open + subscribe to lightweight status diff events.
- Save `reference_matched_geometry_overlay.md` if the matched-geometry effect requires non-obvious coordinator wiring across NSWindow boundaries.
