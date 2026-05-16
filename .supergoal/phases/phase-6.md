SUPERGOAL_PHASE_START
Phase: 6 of 9 — F · Left sidebar (projects + worktrees)
Task: Wrap WindowRootView's content in an `HStack(LeftSidebar, PaneTree)` with a collapsible LeftSidebar (default visible). Sidebar has two sections — Projects (recent projects from ProjectStore) and Worktrees (GitService-fed list for the current project). Cmd-Shift-S toggles visibility; Cmd-Shift-W opens a new-worktree sheet.
Type: brownfield, ui, integration
Mandatory commands: swift test, xcodebuild build, xcodebuild test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 9
Evidence required: build/test/lint clean; screenshot with sidebar visible showing worktrees for the current repo; screenshot of new-worktree sheet open
Depends on phases: 2

## Why

Worktrees + projects are how multi-agent workflows stop colliding on the same checkout. The sidebar makes them first-class.

## Work

- Add `Sources/HangarKit/Sidebar/LeftSidebar.swift`:
  - SwiftUI view (~260pt wide collapsible)
  - Two sections via `Section { ... }` blocks: "Projects" and "Worktrees"
  - Projects section: rows from `appState.projects.list()` with current cwd highlighted
  - Worktrees section: instance of `WorktreeShelfView` (existing) wired to `appState.worktrees(for: currentProject)`
  - Header: "Hangar" wordmark + a small + button for new project

- Add `Sources/HangarKit/Sidebar/NewWorktreeSheet.swift`:
  - SwiftUI sheet prompting for branch name + base ref (default HEAD) + "Open in new tab" toggle
  - On submit: calls `appState.createWorktree(branch:baseRef:openInNewTab:)`

- Extend AppState with:
  - `let projects: ProjectStore`
  - `var sidebarVisible: Bool = true`
  - `var newWorktreeSheetPresented: Bool = false`
  - `var worktreesByProject: [UUID: [Worktree]] = [:]`
  - `func refreshWorktrees(for project: Project)` — calls GitService.worktrees(in: project.cwd)
  - `func createWorktree(branch:baseRef:openInNewTab:)` — GitService.createWorktree + refresh + optionally spawn new pane

- WindowRootView layout becomes:
  ```
  VStack {
      WindowOverlayBar(...)
      HStack(spacing: 0) {
          if appState.sidebarVisible { LeftSidebar(...).frame(width: 260) }
          PaneTreeView(...).frame(maxWidth: .infinity)
      }
  }
  ```

- Cmd-Shift-S binding via SwiftUI Command: toggles `appState.sidebarVisible`
- Cmd-Shift-W binding: sets `appState.newWorktreeSheetPresented = true`
- Sheet attached to ContentView via `.sheet(isPresented:)`

- Tests under `Tests/HangarCoreTests/Git/`:
  - `GitServiceLiveTests` (gated `#if INTEGRATION_TEST`) — create temp repo, init, commit, run `worktrees(in:)` returns 1; `createWorktree(...)` adds a second
  - Skip on CI; run locally as `INTEGRATION_TEST=1 swift test`

## Acceptance criteria

- LeftSidebar.swift + NewWorktreeSheet.swift exist
- AppState exposes the documented sidebar/worktree state and methods
- WindowRootView includes the HStack-wrapped content with conditional sidebar
- Cmd-Shift-S toggles sidebar (verifiable by automation: open Hangar, press Cmd-Shift-S, capture, verify width differs)
- Cmd-Shift-W opens the sheet
- GitServiceLiveTests passes with `INTEGRATION_TEST=1 swift test` locally and its stdout is committed at `.supergoal/evidence/phase-6-worktree-roundtrip.log` (asserts `git worktree list` shows the created branch by name)
- All existing GitService tests still pass; new live integration test passes locally
- Build/test/lint exit 0
- Smoke screenshots committed: `.supergoal/evidence/phase-6-sidebar.png` and `.supergoal/evidence/phase-6-new-worktree-sheet.png`

## Mandatory commands

- `swift test`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `/opt/homebrew/bin/swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required

- Smoke screenshots committed
- Local integration-test log showing GitService round-trip works against /Users/robert/Code/terminal itself

## Notes

- For the current project, default to "the cwd of the active pane's `emulator`" — track via the OSC 7 hook (already wired) or fall back to user-home.
- LeftSidebar is visible by default; the user can collapse via Cmd-Shift-S. Persist visibility to config.json5 in a follow-up phase (out of scope for v0.2).
