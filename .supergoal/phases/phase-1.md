SUPERGOAL_PHASE_START
Phase: 1 of 9 — A · Output wiring + ShellCommandDetector
Task: PaneViewModel observes its emulator's outputStream, feeds an AgentRegexParser, runs a ShellCommandDetector to spot user-typed commands (`% claude`, `$ codex`), and publishes detectedAgentID + status + model via @Observable so the rest of the UI can react.
Type: brownfield, integration, core
Mandatory commands: swift test, xcodebuild build, xcodebuild test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 10
Evidence required: swift test output naming new test classes, xcodebuild build green, swiftlint+swift-format clean, screenshot of a Hangar window with `claude` running where the model badge would be visible (will be wired into UI in phase B; phase A surfaces detection in a debug overlay or test log)
Depends on phases: none

## Why

Every visible feature downstream — model badge, status pill, approval bell, cost pill, Mission Control — depends on a per-pane state machine that knows what the user is running and what state the agent is in. Phase A makes that state machine real and observable.

## Work

- Add `Sources/HangarCore/Agents/ShellCommandDetector.swift`:
  - Regex over typical prompts: `(?m)^.*?(?:\$|%|❯|>) (\S+)(?: |$)`
  - `func consume(_ text: String) -> [String]` returns command names seen since last call
  - Keep a small rolling buffer of the last ~512 bytes to handle splits across chunks
  - Conservative — return only ASCII identifier-shaped tokens (avoid false positives on `$VAR` etc.)

- Extend `PaneViewModel` (`Sources/HangarKit/Pane/PaneViewModel.swift`):
  - Hold a `parser: AgentRegexParser` (rebuilt when a new agent is detected)
  - Hold a `shellDetector: ShellCommandDetector`
  - `func startObserving()` launches a `Task` that iterates `emulator.outputStream`
  - On each chunk:
    1. Append to `shellDetector` — if a new command is seen and AgentRegistry resolves it to a non-raw profile, swap `detectedAgentID`, `model`, and `parser`
    2. Feed the chunk to `parser.feed(_:)` — collect any `[AgentEvent]` returned
    3. For each event: update `currentStatus` for `.stateChanged`; publish `pendingApprovals`/`pendingCostEvents` arrays (consumed by AppState in later phases)
  - Auto-start observing from `init` (after `emulator.start(...)`)
  - Mark cleanly Sendable; parser mutation happens on the actor's executor (MainActor since PaneViewModel is @MainActor)

- New @Observable fields on PaneViewModel (publicly readable):
  - `var detectedAgentID: AgentProfileID? = nil`
  - `var detectedAgentDisplayName: String? = nil`
  - `var model: String? = nil`
  - `var currentStatus: AgentStatus = .idle`
  - `var pendingApprovals: [ApprovalItem] = []`   // consumed in phase C
  - `var pendingCostEvents: [CostEvent] = []`     // consumed in phase D
  - `var lastBytesReceived: Int = 0`              // for diagnostics

- Add `Sources/HangarCore/Agents/AgentRegistryLookup.swift` extension giving AgentRegistry a `@MainActor` `displayName(for:)`/`model(for:)` convenience the view model can call without the registry's per-init overhead.

- Tests under `Tests/HangarCoreTests/Agents/`:
  - `ShellCommandDetectorTests` — 4+ cases:
    - `% claude\n` → returns `["claude"]`
    - `$ codex --help\n` → returns `["codex"]`
    - chunks split mid-line: feed `% cl` then `aude\n` → returns `["claude"]` on second call
    - non-prompt lines (`echo hi`, `% $VAR=1`) do not return tokens
    - multiple commands across multiple lines

- Tests under `Tests/HangarKitTests/Pane/`:
  - `PaneViewModelObservationTests` (`@MainActor`):
    - Inject a fake `TerminalEmulator` that lets the test push bytes into `outputStream`
    - Push `"% claude\n"` → after a small task yield, `vm.detectedAgentID == "claude_code"`, `vm.detectedAgentDisplayName == "Claude Code"`, `vm.model == "claude-opus-4-7"`
    - Push Claude approval-prompt fixture → `vm.currentStatus == .awaitingApproval`, `vm.pendingApprovals.count == 1`
    - Push a non-agent stream → status stays `.idle`, detected agent stays nil

## Acceptance criteria

- ShellCommandDetector.swift exists with the documented API and 5+ tests passing
- AgentRegistryLookup.swift exists (or equivalent integration) and exposes `displayName(for:)` and `model(for:)`
- PaneViewModel has the 7 new @Observable fields documented above
- PaneViewModel.startObserving is called from init and connects to emulator.outputStream
- PaneViewModelObservationTests covers all 4 scenarios above and passes
- `swift test` exits 0
- `xcodebuild build` exits 0
- `xcodebuild test` exits 0
- `swiftlint --strict` 0 violations
- `swift-format lint --recursive --strict Sources Tests Hangar` 0 violations

## Mandatory commands

- `swift test`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `/opt/homebrew/bin/swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required

- File listing of `Sources/HangarCore/Agents/ShellCommandDetector.swift` and new test files
- `swift test` output showing new test classes pass
- xcodebuild build last 10 lines + exit
- xcodebuild test last 10 lines + exit
- Both lint commands' tail with exit 0
- `.supergoal/evidence/phase-1-detection-log.txt` — a 1-page log of detection events captured from running `swift test --filter PaneViewModelObservationTests -v`

## Notes

- The smoke screenshot for the model badge UI lands in phase B; phase A's "smoke" is the test log proving the state machine fires.
- Use `AsyncStream.makeStream()`'s continuation so tests can push synthetic bytes without an actual PTY.
- AgentRegexParser is currently a value type with mutating `feed`. PaneViewModel holds it as a stored `var` and replaces it when the agent profile changes.
