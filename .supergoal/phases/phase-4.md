SUPERGOAL_PHASE_START
Phase: 4 of 13 — Multi-pane layout (splits, tabs, projects)
Task: Implement the three-layer Project → Window → Pane model with horizontal/vertical splits, draggable dividers, native tabs, multi-window support, and SQLite-backed project persistence.
Type: greenfield, core
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 13
Evidence required: build/test exit codes, screenshot of a 3-split window with native tabs, project list persisted across restart, test summary
Depends on phases: 2, 3

## Why

A terminal that can't split is not a terminal in 2026. Projects scope agent presets, cwd, env, and cost ledgers — they're the real unit of work. This phase delivers the structural skeleton everything UI hangs off.

## Work

- Add `Sources/HangarCore/Model/`:
  - `Project` — `id`, `name`, `cwd: URL`, `env: [String:String]`, `defaultAgent: AgentProfileID?`, `createdAt`, `lastOpenedAt`
  - `PaneNode` — recursive enum: `case pane(PaneID)`, `case split(orientation: Axis, ratio: CGFloat, children: [PaneNode])`
  - `Tab` — `id`, `title`, `root: PaneNode`, `activePaneID: PaneID`
  - `WindowSnapshot` — `id`, `projectID: Project.ID?`, `tabs: [Tab]`, `activeTabID`
- Add `Sources/HangarCore/Persistence/`:
  - GRDB database setup; migrations folder; tables `projects`, `windows`, `tabs`, `panes` (PaneNode serialized as JSON blob in tabs.layout)
  - `ProjectStore` actor with `list()`, `create(name:cwd:)`, `update(_:)`, `delete(_:)`, `recent(limit:)`
  - `WindowStore` actor with `save(_:)`, `restoreAll()`, `delete(_:)`
- Add `Sources/HangarKit/Layout/`:
  - `SplitView` — generic SwiftUI view rendering `PaneNode` recursively; uses `HSplitView`/`VSplitView` (AppKit-bridged) for native dragging
  - `PaneContainerView` — wraps a `TerminalPaneView`; click-to-focus, focus ring (1pt accent border)
  - `WindowChromeView` — title bar with project switcher (left), native tab strip (center), placeholder right cluster (cost pill + bell come in Phases 6/8)
- Keyboard handling at the window level:
  - Cmd-D — split current pane horizontally (vertical divider)
  - Cmd-Shift-D — split current pane vertically (horizontal divider)
  - Cmd-W — close current pane (close window if last pane)
  - Cmd-T — new tab
  - Cmd-Shift-] / Cmd-Shift-[ — next/prev tab
  - Cmd-N — new window
  - Cmd-Option-arrows — navigate focus between panes
- Hangar menu structure (full): Hangar (About, Preferences Cmd-,, Quit), File (New Window, New Tab, Open Project, Close), Edit (Copy, Paste, Find), View (Toggle Sidebar, Toggle Sidecar, Mission Control Cmd-0), Window (Minimize, Bring All to Front), Help (Hangar Docs)
- Project switcher: a popover at title-bar left listing recent projects + "Open Project…" (NSOpenPanel folder selection); selecting one opens a new window with that project's cwd
- Saved layouts: on `applicationWillTerminate`, persist all open windows; on next launch, restore (respecting `general.startup` config)
- Tests under `Tests/HangarCoreTests/Layout/` + `Tests/HangarCoreTests/Persistence/`:
  - `PaneNodeSplitTests` — split/merge node tree operations preserve other panes; round-trip JSON
  - `ProjectStoreTests` — create, list, recent ordering, delete cascade
  - `WindowStoreTests` — save/restore a 2-tab, 3-pane window; verify identical structure
  - `KeybindingTests` — assert each shortcut maps to the right command in the keyboard router

## Acceptance criteria (all must pass — verify each in transcript)

- `Project`, `PaneNode`, `Tab`, `WindowSnapshot` types declared in `HangarCore/Model/`
- GRDB migration creates `projects`, `windows`, `tabs`, `panes` tables on first launch
- Cmd-D splits current pane horizontally; both children get focus ring and divider is draggable
- Cmd-Shift-D splits vertically; same behavior
- Cmd-T opens a new native tab in the current window
- Cmd-N opens a new window
- Cmd-W closes the current pane; if it's the last, the window closes
- Cmd-Option-Right moves focus to the right neighbor pane (and the equivalent for other arrows)
- Project switcher popover lists projects from `ProjectStore.recent`
- Opening a project creates/reuses a window with the project's cwd as the new pane's working directory
- App relaunch restores prior windows when `general.startup = restore_last`
- All four layout/persistence test classes pass
- Build / test / lint exit 0

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of new types and views
- Test runner output naming the four new test classes
- `.supergoal/evidence/phase-4-three-split.png` — screenshot of a window with 3 panes (one tab) showing the active focus ring
- Brief paragraph describing the saved-state round-trip smoke (open project, split panes, quit, relaunch, verify layout)

## Notes

- Consult `macos` skill for native tab integration (`NSWindow.tabbingMode`, `NSWindow.tabbingIdentifier`) — SwiftUI's tab support is limited; AppKit bridge is necessary for native-feeling tabs.
- HSplitView/VSplitView are deprecated in pure SwiftUI; use `NSSplitViewController`-backed `NSViewRepresentable` for buttery drag behavior, or use the new `SplitView` API in macOS 26 (Liquid Glass-era splits are native — verify via Context7).
- GRDB migration files live under `Sources/HangarCore/Persistence/Migrations/`. Use timestamped names (`20260516120000_initial.sql.swift`).
- Save `reference_native_tabs_swiftui.md` if AppKit-native tab integration on macOS 26 has a non-obvious wiring step.
