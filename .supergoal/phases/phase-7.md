SUPERGOAL_PHASE_START
Phase: 7 of 9 — G · Right sidecar (diff)
Task: Add a collapsible right-edge sidecar showing the diff of files modified in the current project root. The DiffSidecarView (already exists) is wired to FSEventsWatcher + DiffService. Cmd-Option-D toggles visibility.
Type: brownfield, ui, integration
Mandatory commands: swift test, xcodebuild build, xcodebuild test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 8
Evidence required: build/test/lint clean; screenshot with sidecar visible showing at least one diff row after a file edit in the project root
Depends on phases: 2, 6

## Why

Closes the feedback loop on agent file edits. The user sees what the agent touched in real time.

## Work

- Extend AppState with:
  - `var sidecarVisible: Bool = false` (collapsed by default; user opens explicitly)
  - `var liveDiffs: [Diff] = []`
  - `let fsEventsWatcher: FSEventsWatcher?` — instantiated when a project root becomes active
  - `func startWatching(_ root: URL)` — re-creates watcher; subscribes to `.updates`; for each FileChange computes a Diff via DiffService.compare(baseline: gitShowAtHEAD, current: diskContents, path:)
  - `func stopWatching()`

- WindowRootView layout updates to a 3-column HStack when both panels are open:
  ```
  HStack(spacing: 0) {
      if sidebarVisible { LeftSidebar }
      PaneTree
      if sidecarVisible { DiffSidecarView(diffs: appState.liveDiffs, ...) .frame(width: 320) }
  }
  ```

- Cmd-Option-D binding via SwiftUI Command toggling `appState.sidecarVisible`

- Helper for git-baseline content (small wrapper around `git show HEAD:<path>` via GitService):
  - `GitService.baselineContents(for path: URL, repoRoot: URL) throws -> String`
  - Returns "" if file not in HEAD (new file case)

- Tests under `Tests/HangarCoreTests/Watcher/` and `Diff/`:
  - `LiveDiffPipelineTests` (integration, gated `#if INTEGRATION_TEST`):
    - Init temp repo with a file at HEAD
    - Modify the file
    - Wait for FSEventsWatcher to emit
    - Verify AppState.liveDiffs contains the file with the expected hunks

## Acceptance criteria

- AppState.sidecarVisible + liveDiffs + fsEventsWatcher + startWatching/stopWatching exist
- DiffService and GitService.baselineContents wired into AppState.startWatching
- WindowRootView includes the sidecar conditionally
- Cmd-Option-D toggles visibility
- LiveDiffPipelineTests passes locally (Integration tag)
- Existing DiffServiceTests + FSEventsWatcher tests still pass (no regression)
- Build/test/lint exit 0
- Smoke screenshot at `.supergoal/evidence/phase-7-diff-sidecar.png` showing at least one diff row after editing `Sources/HangarCore/HangarCore.swift` (touch a comment, save)

## Mandatory commands

- `swift test`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `/opt/homebrew/bin/swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required

- Smoke screenshot
- Test runner output naming LiveDiffPipelineTests

## Notes

- Cap liveDiffs to the most recent 30 files so the sidecar list doesn't grow unbounded.
- Granular per-hunk revert lands in v0.3 — DiffSidecarView's row already shows +N/-M counts, that's enough for v0.2.
