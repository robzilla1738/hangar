SUPERGOAL_PHASE_START
Phase: 5 of 13 — Agent profile system
Task: Implement the AgentProfile protocol with built-in profiles for Claude Code, Codex CLI, Hermes, and raw shell; auto-detect the profile on pane spawn by foreground process name; expose model/provider/token metadata to the UI layer via @Observable.
Type: greenfield, core
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 11
Evidence required: build/test exit codes, recorded session fixture parsing test results, screenshot of a pane with model badge visible
Depends on phases: 2, 4

## Why

Agent awareness is the product. This phase is the source of truth — every later UX phase (status pill, approval inbox, mission control, cost ledger) consumes the AgentProfile output. Without it, Hangar is just a terminal.

## Work

- Add `Sources/HangarCore/Agents/`:
  - `AgentProfile` protocol:
    - `id: AgentProfileID`
    - `displayName: String`
    - `defaultBinaryNames: [String]` (e.g. `["claude"]`, `["codex"]`, `["hermes"]`)
    - `provider: Provider` (enum: `anthropic`, `openai`, `nous`, `other`, `none`)
    - `defaultModelHint: String?` (used until output reveals real model)
    - `makeParser() -> AgentOutputParser`
    - `approvalPromptRegexes: [NSRegularExpression]`
    - `costParser: CostParser?` (Phase 8 fills these in fully; Phase 5 leaves them as nil-allowed stubs)
  - `AgentOutputParser` protocol with state machine:
    - States: `idle`, `thinking`, `running_tool(name: String)`, `awaiting_approval(prompt: String)`, `errored(message: String)`, `done`
    - `feed(_ chunk: Data) -> [AgentEvent]` (event types: `stateChanged`, `tokenUsage`, `fileEdited(path:String)`, `messageEmitted(role:String, text:String)`)
  - `AgentDetector` actor: given a pane and the child PID, periodically inspect `/proc`-equivalent (on macOS: `proc_pidinfo` / `PROC_PIDT_SHORTBSDINFO` + `proc_pidpath`) to find the foreground process within the PTY. Match against `defaultBinaryNames` of each registered profile, also consulting `config.agents.extra` from Phase 3. Falls back to `RawShellProfile`.
- Built-in profiles:
  - `ClaudeCodeProfile` — binary `claude`; Anthropic; default model hint `claude-opus-4-7`; approval-prompt regexes for common Claude Code "allow" patterns; emits `messageEmitted` on `Human:` / `Assistant:` markers
  - `CodexProfile` — binary `codex`; OpenAI; default model hint `gpt-5-codex`; approval-prompt regexes for Codex's `Run this command? [y/N]` style; tool-call detection on `> Running ...`
  - `HermesProfile` — binary `hermes`; Nous; default model hint `hermes-3-405b`; conservative regex set (will be tightened as we record fixtures)
  - `RawShellProfile` — fallback when nothing matches; state stays `idle`; no approval routing
- Recorded fixtures under `Tests/HangarCoreTests/Agents/fixtures/`:
  - `claude-code-approval.ansi`, `claude-code-thinking.ansi`, `claude-code-done.ansi`
  - `codex-approval.ansi`, `codex-thinking.ansi`, `codex-done.ansi`
  - `hermes-approval.ansi`, `hermes-thinking.ansi`, `hermes-done.ansi`
  - For v0.1, capture fixtures by running each agent against a known trivial prompt with `script -q -t 0 fixtures/<file>` and committing the raw bytes
- Tests:
  - `AgentOutputParserStateMachineTests` — feed each fixture into the corresponding parser and assert the expected sequence of `AgentEvent`s
  - `AgentDetectorTests` — spawn a process running `/bin/sh -c "exec claude --help"` (or a fake binary that immediately exits) and verify the detector picks the right profile
  - `ConfigCustomAgentExtraTests` — load a config with one entry in `agents.extra` and verify the detector matches that binary
- UI wiring:
  - `PaneViewModel` gains `currentAgent: AgentProfileID?`, `currentStatus: AgentStatus`, `model: String?`
  - Pane header shows a small model badge (text-only for v0.1; designed for Liquid Glass pill in Phase 11) — only when `currentAgent != nil && currentAgent != .rawShell`
  - Status icon placeholder (dot color: gray idle, blue thinking, yellow awaiting, red errored, green done) — full polish in Phase 6

## Acceptance criteria (all must pass — verify each in transcript)

- `AgentProfile` protocol declared with all required members
- Four built-in profiles (`ClaudeCodeProfile`, `CodexProfile`, `HermesProfile`, `RawShellProfile`) implemented and registered in an `AgentRegistry`
- `AgentDetector` returns the right profile when the foreground process is `claude`, `codex`, or `hermes` (tested with stub binaries)
- Foreground-process detection updates within ~500ms of agent launch
- `config.agents.extra` from Phase 3 successfully registers a custom detector
- Recorded fixtures exist for at least three event types per profile (approval, thinking, done — 9 fixtures total)
- All three test classes pass and assert >= 3 `AgentEvent` sequences per profile
- Pane header shows the model badge when an agent profile is active
- Status state machine transitions are observable via `PaneViewModel.currentStatus` and update in tests
- Build / test / lint exit 0
- No false-positive matches: a pane running `vim` does not get mistaken for an agent profile

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of `Sources/HangarCore/Agents/` and `Tests/HangarCoreTests/Agents/fixtures/`
- Test output naming AgentOutputParserStateMachineTests with per-fixture pass/fail
- One screenshot at `.supergoal/evidence/phase-5-model-badge.png` showing a pane with the model badge visible (Claude Code launched in pane)

## Notes

- Consult `swift` skill for Swift 6 strict-concurrency-safe actor design around `AgentDetector`.
- Use `libproc` (`#include <libproc.h>`) via a bridging header for `proc_pidpath` / `proc_listpids`. This is standard macOS practice.
- The PTY's child PID is what we already track in `PTYProcess`. The "foreground process" inside the PTY may be a child of zsh (e.g. zsh forks `claude`). Walk the process tree from the PTY's session leader to find the actual foreground.
- Fixture capture command for record-once-replay-forever: `script -q -t 0 fixtures/claude-code-thinking.ansi -c "claude -p 'say hi briefly' --no-mcp"` — adapt per agent. Run interactively, commit the bytes.
- Memory writeback: save `reference_proc_pidpath_macos26.md` if `libproc` has any macOS 26-specific changes worth recording.
