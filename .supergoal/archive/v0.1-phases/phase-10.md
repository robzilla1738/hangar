SUPERGOAL_PHASE_START
Phase: 10 of 13 — Diff sidecar (FSEvents)
Task: Build a right-sidecar that watches the current project's filesystem via FSEvents and shows live diffs of files touched by any agent, with click-to-revert hunk support (basic), and a per-file "who touched this last" attribution heuristic.
Type: greenfield, ui, core
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 10
Evidence required: build/test exit codes, screenshot of sidecar with one diff, FSEvents test summary
Depends on phases: 4

## Why

Agents edit files. Today you eyeball changes via `git diff` after the fact. The sidecar makes file edits a first-class part of the agent feedback loop and gives the user a sense of what's happening as it happens.

## Work

- Add `Sources/HangarCore/Watcher/`:
  - `FSEventsWatcher` actor wrapping `FSEventStreamCreate`; per-project subscription with debounce (250ms)
  - Events: `[FileChange]` — `path: URL`, `kind: .created | .modified | .removed | .renamed`, `mtime`
  - Ignored paths: `.git/`, `node_modules/`, `DerivedData/`, anything in `config.appearance` ignore patterns (basic for v0.1 — full glob support v0.2)
- Add `Sources/HangarCore/Diff/`:
  - `DiffService` — given a file path, returns `Diff` containing hunks against the file's last-known clean state (initially: current HEAD blob via `git show HEAD:<path>`; falls back to "" for new files)
  - `Diff` — `path: URL`, `hunks: [Hunk]`; `Hunk` — `lineStart`, `lineEnd`, `added: [Line]`, `removed: [Line]`
  - Lightweight Myers diff implementation (or pull in a maintained Swift diff lib via SPM — verify via Context7)
- Attribution heuristic:
  - When a file change event fires, find the most recently active pane whose cwd contains the file, and attribute the change to that pane's agent
  - Store attribution in an in-memory map; persist top-N to SQLite for the timeline
- Add `Sources/HangarKit/Sidecar/`:
  - `RightSidecar` — collapsible sidecar, View > Toggle Sidecar menu item
  - `DiffSidecarView` — list of changed files (most recent first), each row shows path (truncated), agent badge (from attribution), additions/removals counts
  - `DiffDetailView` — selected file's hunks rendered with line numbers, +/- markers, monospace; per-hunk Revert button (writes back the file with that hunk reverted via `git checkout` shell-out — for v0.1, full file revert; granular hunk revert is v0.2)
  - "Lock file" toggle on the row: marks a file as locked in an in-memory set; future Phase will integrate with agents (v0.2)
- Tests under `Tests/HangarCoreTests/Watcher/` + `Tests/HangarCoreTests/Diff/`:
  - `FSEventsWatcherDebounceTests` — fire 20 events in 100ms; assert exactly one debounced delivery
  - `FSEventsWatcherIgnoreRulesTests` — `.git/` writes do not deliver
  - `DiffServiceUnchangedTests` — when file equals HEAD, diff is empty
  - `DiffServiceNewFileTests` — file with no HEAD entry diffs as all-added
  - `DiffServiceModifiedTests` — single-line modification yields one hunk with one added + one removed

## Acceptance criteria (all must pass — verify each in transcript)

- FSEvents subscription starts when a project opens and stops when it closes
- Modifying a file in the project root within ~500ms triggers a sidecar update
- Ignored paths (`.git/`, `node_modules/`) do not generate sidecar entries
- Diff rendering shows line numbers, +/- markers, color-coded fg
- Attribution badge appears on rows with an active agent pane that owns the cwd
- Click a file row to show its hunks
- Per-file revert button (v0.1: whole-file revert) calls `git checkout -- <path>` and the row clears
- All five test classes (2 watcher + 3 diff) pass
- View > Toggle Sidecar opens/closes the sidecar
- Build / test / lint exit 0

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of `Sources/HangarCore/Watcher/`, `Sources/HangarCore/Diff/`, `Sources/HangarKit/Sidecar/`
- Test output naming the five new test classes
- `.supergoal/evidence/phase-10-sidecar.png` — screenshot showing sidecar with one file diff visible

## Notes

- FSEvents on macOS 26 still uses the BSD-y `FSEventStreamCreate`/`FSEventStreamCallback` API; SwiftUI doesn't wrap it, so a small C-callback to Swift trampoline is needed.
- Diff lib options: roll a small Myers + LCS in pure Swift (~250 lines), or use `Foundation`'s `CollectionDifference.difference(from:)` for line-level diffs which is good enough for v0.1.
- Granular per-hunk revert is v0.2; full-file revert is v0.1.
- Save `reference_fsevents_macos26.md` if any quirk surfaces with the callback retention on macOS 26.
