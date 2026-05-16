SUPERGOAL_PHASE_START
Phase: 8 of 9 — H · Terminal table-stakes
Task: Ship the keyboard-shortcut and behavioral table-stakes any modern terminal needs — native tabs, font sizing, find, clear, URL Cmd-click, drag-folder-to-paste, restore-last-state.
Type: brownfield, ui, terminal
Mandatory commands: swift test, xcodebuild build, xcodebuild test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 12
Evidence required: build/test/lint clean; one composite screenshot showing 2 tabs + a split + font visibly larger than default; per-feature confirmation in the phase log (manual smoke checklist)
Depends on phases: 1

## Why

Without these, "agentic terminal" is a niche curiosity. With them, Hangar can be the user's daily driver.

## Work

- **Native tabs (Cmd-T)**:
  - SwiftUI WindowGroup natively supports tab merging on macOS when `windowResizability` and command surface allow it
  - Add `CommandGroup(after: .newItem)` with `Button("New Tab") { /* open a new window the OS will merge into the current tab group */ }.keyboardShortcut("t", modifiers: [.command])`
  - Configure NSWindow.tabbingMode = .preferred in WindowConfigurator so new windows merge into tab groups
  - Update Window menu's Show Tab Bar / Move Tab to New Window (free with NSWindow tabbing)

- **Font sizing (Cmd-= / Cmd--)**:
  - SwiftUI commands that update `appState.config.fonts.size` (clamp 9..30) and write through ConfigStore
  - Add `appState.applyFont()` that sets each PaneViewModel's emulator's font to `NSFont.monospacedSystemFont(ofSize: CGFloat(size), weight: .regular)`

- **Find (Cmd-F)**:
  - Add a SearchBar overlay (slide down from top of WindowOverlayBar) with TextField
  - Use SwiftTerm's existing search APIs (`TerminalView.search(forward:text:)`) — verify API via the package source
  - Esc closes search

- **Clear (Cmd-K)**:
  - Write `\x1b[2J\x1b[H` (or `\x1bc` for full reset) to the active pane

- **URL Cmd-click**:
  - SwiftTerm's TerminalView fires a delegate hook on Cmd-click that includes the clicked text
  - Subscribe and if the clicked range parses as a URL via `URL(string:)` + scheme in `[http, https, file, mailto]`, call `NSWorkspace.shared.open(url)`

- **Drag folder onto pane**:
  - On `TerminalPaneView`/`TerminalHostView`, register for the `.fileURL` drop type
  - On drop, get the file URL and `emulator.send(text: url.path + " ")` so the path is pasted with a trailing space

- **Restore last state**:
  - On `applicationWillTerminate`, capture a `[WindowSnapshot]` of every open window
  - Persist via JSON to `~/.config/hangar/state.json`
  - On launch, if `config.general.startup == .restoreLast`, read state.json and recreate the windows

- Tests:
  - `Tests/HangarCoreTests/Restore/WindowSnapshotPersistenceTests` — round-trip 2 windows × 3 panes
  - `Tests/HangarKitTests/Terminal/FontSizingTests` — assert AppState.applyFont propagates to a fake emulator's font property

## Acceptance criteria

- Cmd-T opens a new tab in the same window group
- Cmd-= bumps font size by 1; Cmd-- drops by 1; persists to config.json5
- Cmd-F slides down a search overlay; Esc closes it
- Cmd-K clears the active pane
- Cmd-click on a URL opens it in the default browser
- Drag-drop a Finder folder onto a pane pastes the path with a trailing space
- Restore-last-state works when `general.startup = restore_last` (verified by launch → open extra window → quit → relaunch → both windows reappear)
- Existing build/test/lint stay green; new test classes pass
- Build/test/lint exit 0
- Smoke composite screenshot `.supergoal/evidence/phase-8-table-stakes.png` showing 2 tabs in a window + a horizontal split + visibly larger font
- A structured smoke checklist committed at `.supergoal/evidence/phase-8-table-stakes-checklist.md` with one row per feature: (feature name, command/gesture tried, observed outcome, screenshot path), all 7 rows marked ✅

## Mandatory commands

- `swift test`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `/opt/homebrew/bin/swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required

- Composite smoke screenshot
- Per-feature smoke confirmations in the phase log

## Notes

- SwiftTerm's `TerminalView.search` API may have moved between minor versions; verify against `.build/checkouts/SwiftTerm/Sources/SwiftTerm/MacTerminalView.swift` and use whatever the public surface is. If unavailable, ship a minimal client-side find that selects matching ranges in the buffer.
- For native tabs, the user's macOS "Prefer Tabs" setting interacts. Document this in the user-facing CHANGELOG.
