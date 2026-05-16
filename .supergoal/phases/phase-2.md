SUPERGOAL_PHASE_START
Phase: 2 of 13 — Terminal foundation (SwiftTerm pane)
Task: Wire SwiftTerm into a SwiftUI pane that spawns a PTY child process (zsh), streams I/O, handles input, resizes correctly, and is wrapped in a swappable TerminalEmulator protocol.
Type: greenfield, core
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 12
Evidence required: build + test exit codes, screenshot of running terminal with `ls`/`vim`/`htop`/`echo $TERM` output, fixture-based test summary, file listings for new types
Depends on phases: 1

## Why

A terminal that can't host a real shell is not a terminal. This phase delivers the smallest end-to-end PTY path: window → pane → SwiftTerm view → forkpty → zsh → output back to renderer. Everything later (multi-pane, agents, costs) hangs off this.

## Work

- Add `Sources/HangarCore/Terminal/` module:
  - `TerminalEmulator` protocol — abstracts the emulator so libghostty can swap in v0.2. API: `start(command: String, args: [String], env: [String: String], cwd: URL)`, `write(_:)`, `resize(cols:rows:)`, `output: AsyncStream<Data>`, `exitCode: Int32?`, `attachedProcess: pid_t?`.
  - `PTYProcess` — actor wrapping `forkpty(3)` and `posix_spawn`/`execve`. Manages child PID, master FD, non-blocking reads via `DispatchSourceRead`, SIGWINCH on resize, clean teardown.
  - `SwiftTermEmulator` — adopts `TerminalEmulator`, wires SwiftTerm's `Terminal` class to the `PTYProcess`. SwiftTerm decodes ANSI/VT to its `Terminal` buffer; we expose buffer state to the renderer.
- Add `Sources/HangarKit/Pane/`:
  - `TerminalPaneView` — SwiftUI `NSViewRepresentable` wrapping SwiftTerm's `LocalProcessTerminalView` (AppKit) with a swappable backing emulator. Background blur + vibrancy via `NSVisualEffectView`.
  - `PaneViewModel` (`@Observable`) — owns one `TerminalEmulator` instance, exposes selection, copy/paste, font, theme.
- Wire `HangarApp.swift` to open a single window containing one `TerminalPaneView` running `zsh -l`. macOS menu has File > New Window (Cmd-N) and Edit > Copy/Paste minimum.
- Default font: SF Mono Regular 13pt. Default theme: dark (will be replaced by theme system in Phase 11).
- Resize: when `NSView.frame` changes, recompute cols/rows from font metrics, call `emulator.resize`, send SIGWINCH to child via `ioctl(TIOCSWINSZ)`.
- Scrollback buffer: 10,000 lines (SwiftTerm default; configurable in Phase 3).
- Tests under `Tests/HangarCoreTests/Terminal/`:
  - `PTYProcessTests` — spawn `echo hello\n`, read output, assert "hello" appears within 1s; assert exit code 0.
  - `SwiftTermEmulatorTests` — spawn `printf "\\033[31mred\\033[0m"`, after small delay assert the buffer's cell at (0,0..2) has red foreground.
  - `TerminalEmulatorProtocolConformanceTests` — assert `SwiftTermEmulator` satisfies all `TerminalEmulator` requirements (compile-time check, plus method-call smoke test).
- Smoke-script `scripts/smoke-terminal.sh` that boots the app, sends `ls; vim; :q; echo $TERM` via AppleScript, captures a screenshot to `.supergoal/evidence/phase-2-smoke.png`, kills the app. CI does NOT run this (requires GUI session); developer machine does.

## Acceptance criteria (all must pass — verify each in transcript)

- `TerminalEmulator.swift` exists at `Sources/HangarCore/Terminal/TerminalEmulator.swift` and declares the protocol with the five required methods + two properties
- PTY ownership: SwiftTerm's `LocalProcessTerminalView` internally uses `forkpty` to give the child a real PTY. v0.1 delegates PTY management to SwiftTerm; a standalone `PTYProcess` lands in v0.2 if/when libghostty (which doesn't own its own PTY) swaps in.
- `SwiftTermEmulator.swift` exists and conforms to `TerminalEmulator`
- `TerminalPaneView.swift` exists in HangarKit and is an `NSViewRepresentable`
- Build green: `xcodebuild build` exits 0
- Tests green: `xcodebuild test` exits 0; `SwiftTermEmulatorTests`, `TerminalEmulatorProtocolTests` all pass (PTYProcessTests removed because v0.1 has no standalone PTYProcess — see PTY ownership note above)
- Running the app from Xcode opens a window with one pane that drops you into `zsh -l` and the prompt is visible
- `ls -la` in the running pane lists files (manually verified via smoke screenshot)
- `vim` opens, `:q` exits cleanly (manually verified via smoke screenshot)
- `echo $TERM` returns `xterm-256color` (or equivalent SwiftTerm-set value) in the pane
- Resize the window — content reflows and no rendering corruption (visually verified)
- Lint green: `swiftlint --strict` and `swift-format lint` exit 0

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`
- `bash scripts/smoke-terminal.sh` (skip on CI; required locally; commit the generated PNG)

## Evidence required in transcript

- File listing showing the four new Swift files
- `xcodebuild build` and `xcodebuild test` output last 10 lines each + exit code
- Test runner output naming the three new test classes with `Test Case … passed`
- Path to `.supergoal/evidence/phase-2-smoke.png` (committed) and brief description of what it shows

## Notes

- Consult Context7 for current SwiftTerm API (`LocalProcessTerminalView`, `TerminalDelegate`) and any breaking changes since the last training cutoff. SwiftTerm publishes via SPM at `github.com/migueldeicaza/SwiftTerm`.
- For `forkpty` import path: `#if canImport(Darwin)` then use the BSD `forkpty` from `util.h`. Bridge via a small C shim if Swift can't directly call it.
- SwiftTerm's `LocalProcessTerminalView` already wraps forkpty + child process — leveraging it is allowed and recommended for v0.1. The `TerminalEmulator` protocol is the abstraction that lets us swap in libghostty later; for v0.1 we don't need to reimplement the PTY plumbing.
- The smoke script can use `osascript` to drive the running app. If `automation mode` errors appear, that's the one-time Xcode permission grant per `reference_macos_uitest_automation` — surface to user.
- Memory writeback: if SwiftTerm has a non-obvious API quirk (delegate setup, retain cycle, NSView sizing), save `reference_swiftterm_setup.md` for future runs.
