SUPERGOAL_PHASE_START
Phase: 3 of 13 — Config + hot reload
Task: Implement Hangar's JSON5 config file at ~/.config/hangar/config.json5 with typed schema, defaults, file-watcher hot reload, and a Settings sheet that displays the live config (read-only viewer in v0.1).
Type: greenfield, core
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 10
Evidence required: build/test exit codes, config file generated on first launch, hot-reload demo (edit JSON5 → app reflects without restart), test summary
Depends on phases: 1

## Why

Themes, fonts, agent paths, hotkeys, and cost thresholds all need a single source of truth. Hot reload (Hashimoto-style) is the user-pleasing detail that signals craftsmanship. Doing config early prevents every later phase from hardcoding values.

## Work

- Add `Sources/HangarCore/Config/`:
  - `HangarConfig` — `Codable` struct with all settings; defaults baked into the type
  - Sections (top-level keys): `general`, `appearance`, `fonts`, `agents`, `keybindings`, `costs`, `worktree`, `experimental`
  - Detailed schema:
    - `general.startup`: `new_window | restore_last`
    - `appearance.theme`: string (`hangar-dark`, `hangar-light`, or path to custom)
    - `appearance.transparency`: 0.0–1.0
    - `appearance.titlebar_style`: `unified | inset`
    - `fonts.family`: string (default "SF Mono")
    - `fonts.size`: int (default 13)
    - `fonts.line_height`: double (default 1.2)
    - `agents.claude_code.binary`: string (default "claude")
    - `agents.codex.binary`: string (default "codex")
    - `agents.hermes.binary`: string (default "hermes")
    - `agents.extra`: array of `{name, binary, profile}` custom detectors
    - `keybindings.mission_control`: string (default "cmd+0")
    - `keybindings.approval_inbox`: string (default "cmd+shift+a")
    - `keybindings.new_worktree`: string (default "cmd+shift+w")
    - `costs.warn_at_usd`: double (default 20.0)
    - `costs.hard_stop_at_usd`: double | null (default null)
    - `worktree.base_dir`: string (default "~/Hangar/Worktrees")
    - `experimental.use_libghostty`: bool (default false)
- Add a JSON5 parser dependency (`https://github.com/cgossain/JSON5Kit` or equivalent — verify via Context7 before locking)
- `ConfigStore` actor:
  - `current: HangarConfig` (snapshot)
  - `load()` — parse `~/.config/hangar/config.json5`; if missing, write defaults and load
  - `watch()` — `DispatchSourceFileSystemObject` on the file; on `.write|.delete|.rename`, re-parse and publish a new snapshot via `AsyncStream<HangarConfig>` (`changes`)
  - `validateAndCoerce(_:)` — on parse error, surface a `ConfigParseError` with line/column; fall back to current snapshot and post a non-fatal banner
- `HangarKit/Settings/SettingsView` — SwiftUI sheet (read-only viewer for v0.1) using `Form` + `LabeledContent`; shows the parsed config and a "Reveal config in Finder…" button
- Wire `PaneViewModel`, `TerminalPaneView`, and `HangarApp` to consume `ConfigStore.changes`:
  - Font family/size changes apply to all live panes
  - Transparency change applies immediately
  - Other sections stored but unused until later phases (agent paths used in Phase 5, hotkeys in Phase 6, etc.)
- Tests under `Tests/HangarCoreTests/Config/`:
  - `ConfigDefaultsTests` — writing defaults to a temp dir then re-reading reproduces the same struct
  - `ConfigParseTests` — fixture JSON5 with comments + trailing commas parses cleanly
  - `ConfigParseErrorTests` — malformed JSON5 returns `ConfigParseError` without throwing
  - `ConfigWatcherTests` — write file → wait → modify file → assert two snapshots delivered within 500ms
- Smoke step (local, optional in CI): launch app, edit `~/.config/hangar/config.json5` to set `fonts.size: 16`, observe pane re-renders without app restart.

## Acceptance criteria (all must pass — verify each in transcript)

- `~/.config/hangar/config.json5` is created on first launch if missing
- The file contains a top-level comment header (`// Hangar configuration — see https://github.com/robzilla1738/hangar/docs/config.md`)
- All eight top-level sections present in default file
- `ConfigStore.load()` round-trips defaults (write → read → equal)
- Malformed JSON5 does not crash the app; the existing snapshot is retained
- A file-write triggers a new snapshot on `ConfigStore.changes` within 500ms (test asserted)
- Changing `fonts.size` in the file while app is running updates the running pane's font without restart (manual smoke)
- `SettingsView` opens via Cmd-, and renders the live config; a "Reveal in Finder" button opens the directory
- `docs/config.md` exists with the full schema documented (one section per top-level key)
- All four config test classes pass; `xcodebuild test` exits 0; lint exits 0

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- `cat ~/.config/hangar/config.json5` after first launch — first 30 lines
- File listing of `Sources/HangarCore/Config/` and `Tests/HangarCoreTests/Config/`
- Test runner output naming the four new test classes
- One paragraph describing the hot-reload smoke result

## Notes

- Consult Context7 for current JSON5 SPM packages (`JSON5Kit` is one option; verify or pick the most maintained).
- DispatchSource file watchers on macOS reliably catch atomic writes (`mv tmp file`) — test the watcher against `Foundation.FileHandle.write` AND `mv` to cover both editor behaviors.
- Use Keychain in Phase 12 for any API-key-like config; for v0.1, keep secrets out of `config.json5` entirely.
- Save `reference_config_hot_reload.md` if DispatchSource needs a non-obvious re-arm dance after the file is recreated (common on rename-based atomic writes).
