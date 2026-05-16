# THINKING — Hangar v0.1

## Goals
1. Native macOS terminal that **replaces** the user's daily terminal — not a side experiment.
2. First-class management of multi-agent CLI workflows (Claude Code, Codex CLI, Hermes).
3. Ghostty-grade speed and polish; Apple-native chrome (Liquid Glass on macOS 26 Tahoe).
4. Open source (MIT), BYO API keys, no hosted gateway.
5. Shippable v0.1.0 release on GitHub + Homebrew Cask formula by end of this run.

## Constraints
- macOS 26 Tahoe minimum (full Liquid Glass; SDK is 26.2 per recon)
- Swift 6.2.4 strict concurrency on
- Universal binary (arm64 + x86_64)
- Hardened runtime, Developer ID signed, notarized (cert `9F2JXY8TCK` available)
- No App Sandbox (terminal spawns arbitrary child processes — sandbox is impractical)
- No plugin runtime in v1; AppleScript / Shortcuts hooks only

## Stack (locked)
- **Language**: Swift 6.2 strict concurrency
- **UI**: SwiftUI for chrome + AppKit bridges (NSWindow, NSMenu, NSApplication delegate, vibrancy)
- **Renderer**: SwiftTerm 1.x for terminal emulation v0.1; design `TerminalEmulator` protocol so libghostty can swap in v0.2
- **Process**: `posix_spawn` + `forkpty` via a thin Swift wrapper actor
- **Persistence**: GRDB.swift over SQLite (sessions, history, costs, fts via SQLite FTS5)
- **Updates**: Sparkle 2 (SPM)
- **Diff**: Apple's `Differ`-style algorithm in Swift; raw line-diff view in v0.1
- **Git**: shell out to `git` via Process (avoid libgit2 dependency for v0.1; revisit in v0.2)
- **Networking**: URLSession (no swift-nio needed in v0.1; cost backfill is HTTP)
- **Project**: Xcode `.xcodeproj` at root + Swift Package targets for testability (modern split)
- **Lint**: SwiftLint + swift-format
- **CI**: GitHub Actions (macos-26 runner image)
- **Release**: tag-driven workflow → universal build → notarize → upload artifact + appcast
- **Distribution**: GitHub Releases + Homebrew Cask (own tap `robzilla1738/hangar`)

## Top 3 risks (+ mitigations)

### 1. SwiftTerm edge cases
SwiftTerm is solid but not Ghostty-grade. Quirks possible with: vim modal weirdness, true color (24-bit), bracketed paste, complex Unicode width, IME composition, alt-screen behavior.
- **Mitigation**: SwiftTerm in v0.1; abstract behind `TerminalEmulator` protocol; smoke-test against the most common offenders (`vim`, `htop`, `nano`, `claude`, `codex`) during Phase 2.
- **Escape hatch**: libghostty swap is a v0.2 plan; if SwiftTerm bombs out on a critical case, fall back to shelling out to `script(1)`-recorded sessions for evidence in tests.

### 2. Agent prompt detection without handshake protocol
Approval prompts differ between Claude Code, Codex CLI, Hermes. Output regex is fragile.
- **Mitigation**: Per-agent profile owns its own regex set, tested against recorded fixtures of real agent output. Conservative defaults; mis-detected prompts surface in inbox with "manual" flag rather than silently auto-routing.
- **Documented escape hatch**: design hooks for an OSC handshake (escape sequence `ESC ] 1337 ; hangar=... BEL`) so agents can opt in later. Doc this in `docs/handshake-protocol.md` for v0.2 community proposal.

### 3. Cost calculation from CLI output
Agents don't emit token counts in a standardized way.
- **Mitigation**: per-profile parsers; show "estimated" cost from output; nightly background reconciliation via provider HTTP APIs (Anthropic, OpenAI) using Keychain-stored API keys → "confirmed" cost.
- **Failure mode that's OK**: if reconciliation fails (no API key, rate limit), cost pill stays in "estimated" mode and badges it. Don't block the UI.

## Dependencies (high-leverage ordering)
- (P1 Bootstrap) **gates everything** — without repo + project structure + CI, no phase verifies.
- (P2 Terminal foundation) **gates** P3 multi-pane and all agent work.
- (P3 Config) **gates** themes/fonts/agent binary overrides used by everything.
- (P4 Multi-pane) **gates** P6 agent awareness UI (status pill needs a pane to attach to).
- (P5 Agent profiles) **gates** P6 awareness + P8 cost ledger.
- (P6 Awareness) **gates** P7 Mission Control (tiles need status).
- (P11 Polish) consumes outputs from every prior phase.
- (P12 Harden) consumes outputs from every prior phase.
- (P13 Distribute) requires everything green + signed cert.

## Memory hits applied (from `applied-memories.md`)
- `user_professional_background` → Polish phase must hit Apple-grade fit and finish; screenshots committed; sane defaults.
- `project_snapnote` → Reuse Sparkle SPM + DMG patterns; Developer ID cert ready (recon confirmed `9F2JXY8TCK`).
- `feedback_dont_run_generators` → For Xcode auth grants / long signing flows, surface command + stop, don't loop.
- `reference_macos_uitest_automation` → If `xcodebuild test` UI runner errors with "automation mode", it's an Xcode permission grant; document in P12.

## Tools / skills relied on (from `tools.md` + `applied-skills.md`)
- **Context7** for SwiftTerm + Sparkle 2 + GRDB.swift docs verification at Phase 1.
- **macos** skill: every SwiftUI/AppKit phase.
- **swift** skill: foundation + concurrency review.
- **design** skill: Polish phase.
- **security** skill: Hardening phase (Keychain, hardened runtime).
- **testing** skill: test scaffolding in Phase 1 + per-feature tests throughout.
- **release-review** skill: pre-tag review in Phase 13.

## Best practices applied
- Swift 6.2 strict concurrency (no `@unchecked Sendable` without justification)
- MVVM with `@Observable` view models; injection via initializers
- Async/await + `AsyncStream` for PTY output streams
- Result types and typed `LocalizedError` for user-facing failures
- Conventional Commits + Semantic Versioning
- SwiftLint + swift-format gates in CI
- Tests: unit (XCTest) + snapshot (where stable) + characterization fixtures for agent output parsing
- Accessibility from day one (VoiceOver labels on every interactive element)
- HIG-compliant menu structure (Hangar > Hangar Menu, Edit, View, Window, Help)
- README badges, demo gif slot, install instructions, contribution guide

## Open assumptions (surface in plan review)
1. macOS minimum target: **macOS 26 Tahoe** (need Liquid Glass; recon confirmed SDK 26.2 available).
2. License: **MIT** (no NOTICE file needed for v0.1).
3. Bundled font: **SF Mono** as default; JetBrains Mono Light bundled as option (free under SIL OFL).
4. Homebrew Cask: **own tap** `robzilla1738/homebrew-hangar` at first (faster to ship); submit to `homebrew/cask` after v0.2 stabilization.
5. Default profile detection runs on **binary name match** of the foreground process; PTY output is parsed for state machine only.
6. **No telemetry, no analytics, no crash reporter network calls** in v0.1. (Add Sparkle's optional anonymous version-check in v0.2.)
7. Sparkle EdDSA key generated in Phase 13; private key stored in `~/.config/hangar-secrets/` (gitignored), public key embedded in `Info.plist`.
8. App icon: **placeholder** for v0.1 (Hangar wordmark on dark gradient); real icon commissioned post-v0.1.
9. Demo gif / Loom video: placeholder slot in README; we'll record once v0.1 builds run.
10. **Code organization**: one Xcode app target (Hangar) + two Swift Package modules (`HangarCore` for non-UI logic, `HangarKit` for UI components) for testability.
