SUPERGOAL_PHASE_START
Phase: 12 of 13 — Harden (security + a11y + perf)
Task: Run security review (Keychain for API keys, hardened-runtime entitlements verified, input validation), accessibility audit (VoiceOver pass on every surface), and performance smoke (cold launch < 100ms, no GPU frame drops at 60 Hz when idle), with concrete fixes for anything red.
Type: hardening
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 14
Evidence required: build/test exit codes, security skill review notes, VoiceOver checklist, Instruments cold-launch trace summary
Depends on phases: 1-11

## Why

Per-phase polish doesn't substitute for an end-to-end pass. This phase is the last opportunity to catch issues before notarization makes diagnosis harder. It also runs the formal `security` skill and `release-review` skill for a senior-dev cross-check.

## Work

- **Security pass** (invoke `security` skill):
  - Audit Keychain integration: `Sources/HangarCore/Secrets/`
    - `Keychain` actor wrapping `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete` with service `dev.robcourson.hangar` and account-per-provider (`anthropic_api_key`, `openai_api_key`, `nous_api_key`)
    - Settings sheet gets a "Provider API keys" section (write only; values write through to Keychain; reads only ever populate masked text fields)
  - Verify entitlements file at `Hangar/Hangar.entitlements`:
    - `com.apple.security.cs.allow-jit` = true
    - `com.apple.security.cs.disable-library-validation` = true
    - `com.apple.security.cs.allow-unsigned-executable-memory` = true (terminals need this for some interpreters)
    - `com.apple.security.cs.allow-dyld-environment-variables` = true (for setting TERM, etc. on child processes)
    - NO Sandbox entitlement
  - Input validation sweep: config parsing (already covered Phase 3), shell-injection in worktree branch name input, FSEvents path normalization (no escaping into parent dirs)
  - No hardcoded secrets in source; grep `git diff <baseline-ref>..HEAD` for `sk-`, `claude-api`, hex of length 40+, common API key patterns
- **Accessibility pass** (invoke `macos` skill for a11y guidance):
  - Run macOS Accessibility Inspector on the running app; capture issues
  - VoiceOver dry run: every pane has rotor entries for "Pane <N>: <agent>"; every popover navigates with Tab; every interactive control has a label and trait
  - Keyboard navigation: ensure menu shortcuts work; every button is reachable via keyboard alone
  - Color contrast verified (already covered Phase 11; re-check after any token tweaks here)
- **Performance pass**:
  - Cold launch: profile with Instruments (Time Profiler), measure from `applicationDidFinishLaunching` to first paint. Target ≤ 100ms on Apple Silicon
  - Frame rate: with one idle pane, run for 60s; GPU frame time ≤ 16.6ms per frame (Instruments Core Animation)
  - Memory: idle 1 pane footprint ≤ 80 MB resident; baseline + leak detection 10-min run
  - Fix any hot spots; common suspects: NSWindow restoration triggering all panes simultaneously, SwiftTerm large scrollback on launch — verify and fix
- **Release-review pass** (invoke `release-review` skill):
  - Pre-tag review against the skill's checklist
  - Document the report in `.supergoal/evidence/phase-12-release-review.md`
  - All P0/P1 findings either fixed in this phase or filed as issues with v0.1.0 milestone

## Acceptance criteria (all must pass — verify each in transcript)

- `Keychain` actor exists and round-trips a test key (add/get/delete) in unit tests
- Settings sheet exposes per-provider key fields (write-only) — verifiable via `SettingsView` snapshot or screenshot
- Entitlements file contents match the spec (grep `Hangar/Hangar.entitlements`)
- Hardened runtime is enabled in build settings (`xcodebuild -showBuildSettings | grep ENABLE_HARDENED_RUNTIME` returns YES)
- Diff sweep for hardcoded secrets returns zero matches
- Accessibility Inspector run records zero P0 issues
- VoiceOver checklist file at `docs/a11y/voiceover-checklist.md` is filled out for every surface (status: ✅/⚠️ per item)
- Cold launch ≤ 100ms (Instruments trace excerpt committed in `.supergoal/evidence/phase-12-cold-launch.png`)
- Idle-pane frame rate sustained ≥ 60fps (Instruments trace committed)
- Idle 1-pane RSS ≤ 80 MB on Apple Silicon (`ps -o rss=` snapshot)
- No memory leaks reported by Instruments Leaks over a 10-minute idle run (zero leaked allocations)
- `release-review` skill report committed at `.supergoal/evidence/phase-12-release-review.md` with all P0/P1 either fixed (commit hash) or filed (issue number)
- All test classes still pass (no regression from Phase 11)
- Build / test / lint exit 0

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of `Sources/HangarCore/Secrets/` and `docs/a11y/`
- Test output naming new Keychain test
- Path to Instruments cold-launch trace excerpt + reported ms
- Path to release-review report
- Brief paragraphs summarizing the a11y, perf, and security findings (with status)

## Notes

- Consult `security`, `macos`, and `release-review` skills.
- `xcodebuild -showBuildSettings -scheme Hangar -configuration Release | grep -i hardened` to verify ENABLE_HARDENED_RUNTIME=YES.
- Save `reference_hardened_runtime_entitlements_terminal_app.md` to memory — the exact entitlement set needed by a terminal-style macOS app is non-obvious and worth recording.
- If the `release-review` skill flags anything truly blocking, treat it as a phase failure and follow the 3-strike recovery in PROTOCOL.md.
