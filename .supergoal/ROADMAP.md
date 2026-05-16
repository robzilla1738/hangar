# Roadmap: Hangar — native macOS agentic terminal (v0.1)

**Task:** Build Hangar, a native macOS terminal designed around managing multiple AI CLI agents (Claude Code, Codex CLI, Hermes), and ship a signed/notarized v0.1.0 release on GitHub + Homebrew Cask tap.
**Type:** greenfield, macOS, ui, swift
**Created:** 2026-05-16
**Total phases:** 13

## Context summary

- **Stack:** Swift 6.2 (strict concurrency) · SwiftUI + AppKit · SwiftTerm 1.x · GRDB.swift · Sparkle 2 · Xcode 26.3 · macOS 26.2 SDK (Tahoe)
- **Package manager:** Swift Package Manager (for libs); Homebrew for system tooling (SwiftLint, xcbeautify, create-dmg)
- **Build / test / lint commands:**
  - `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
  - `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
  - `swiftlint --strict`
  - `swift-format lint --recursive --strict Sources Tests Hangar`
- **Risky areas:** SwiftTerm edge cases (vim, true color, IME); agent prompt regex fragility; cost calc reconciliation; macOS 26 Liquid Glass API churn

## Assumptions

Non-blocking decisions recorded so we can proceed without round-trips. If wrong, stop the run and tell us:

- macOS 26 Tahoe minimum deployment target (SDK 26.2 confirmed; Liquid Glass requires it).
- License: MIT (no NOTICE file in v0.1).
- Default font: SF Mono ships in macOS; JetBrains Mono Light bundled as a built-in option (SIL OFL).
- Homebrew distribution: own tap `robzilla1738/homebrew-hangar` at first; submit to `homebrew/cask` after v0.2.
- Default agent profile detection is binary-name based on the foreground process; PTY output parsing is for state-machine and approval prompts only.
- No telemetry, no analytics, no crash reporter network calls in v0.1.
- Sparkle EdDSA: keys generated in Phase 13; private key stored in `~/.config/hangar-secrets/` (outside repo), public key embedded in `Info.plist`.
- App icon for v0.1: placeholder (Hangar wordmark on dark gradient); real icon post-v0.1.
- Code layout: one Xcode app target (`Hangar`) + two Swift Package modules (`HangarCore` for non-UI logic, `HangarKit` for UI components).
- Hardened runtime entitlements: `com.apple.security.cs.allow-jit`, `com.apple.security.cs.disable-library-validation`. No App Sandbox.
- Team ID: `9F2JXY8TCK`; Developer ID Application: "Robert Courson (9F2JXY8TCK)".
- GitHub repo: `robzilla1738/hangar`, public.

## Risk top 3

1. **SwiftTerm edge cases** — likelihood: medium, mitigation: abstract behind `TerminalEmulator` protocol; smoke-test `vim`/`htop`/`nano`/`claude`/`codex` in Phase 2; document libghostty swap path for v0.2.
2. **Agent prompt detection regex fragility** — likelihood: medium, mitigation: per-profile regex sets tested against recorded session fixtures; conservative defaults; manual-flag fallback in inbox; document OSC handshake spec for v0.2.
3. **Cost calc from CLI output is non-standard** — likelihood: high (correctness), low (UX impact), mitigation: per-profile parsers for "estimated"; nightly background reconciliation via provider APIs for "confirmed"; badge state in UI; don't block on reconciliation failure.

## Phase map

| # | Phase | Depends on | Deliverable |
|---|-------|------------|-------------|
| 1 | Bootstrap repo + project + CI | — | Public GitHub repo `robzilla1738/hangar`, Xcode project, two SPM modules, CI green on push |
| 2 | Terminal foundation (SwiftTerm pane) | 1 | Empty Hangar window with one working PTY pane running zsh |
| 3 | Config + hot reload | 1 | JSON5 config at `~/.config/hangar/config.json5` with file-watcher hot reload of theme/font/agent paths |
| 4 | Multi-pane layout (splits, tabs, projects) | 2, 3 | Splits, tabs, multi-window, projects persisted to SQLite |
| 5 | Agent profile system | 2, 4 | Auto-detect Claude Code / Codex / Hermes / raw shell on pane spawn; profile metadata applied |
| 6 | Agent awareness (status + Approval Inbox) | 5 | Status pill per pane, unified Approval Inbox popover, macOS notifications, Cmd-Shift-A hotkey |
| 7 | Mission Control grid | 6 | Cmd-0 full-window overlay grid of all panes with status, badges, last-3-lines, click-to-focus |
| 8 | Cost ledger + cost pill | 5 | SQLite cost events, per-profile parsers, title-bar cost pill with breakdown sheet |
| 9 | Worktree shelf | 4 | Left-sidebar shelf, Cmd-Shift-W creates worktree, click-to-jump pane |
| 10 | Diff sidecar (FSEvents) | 4 | Right-sidecar live diff via FSEvents per project root |
| 11 | Polish (Liquid Glass + themes + visuals) | 2-10 | Liquid Glass chrome, 2 built-in themes, empty/loading/error states everywhere, committed screenshots |
| 12 | Harden (security + a11y + perf) | 1-11 | Keychain integration, hardened-runtime entitlements, VoiceOver pass, cold-launch < 100ms |
| 13 | Distribute (sign + notarize + release) | 12 | v0.1.0 GitHub release with signed/notarized DMG, Sparkle appcast, Homebrew Cask formula |

---

(Detailed phase specs live at `.supergoal/phases/phase-1.md` through `.supergoal/phases/phase-13.md`. Each spec is read by the executor at runtime and contains its own SUPERGOAL_PHASE_START block, Work, Acceptance criteria, Mandatory commands, and Evidence required sections.)

---

## Final-phase (Phase 13) coverage

Phase 13 is the "Distribute" phase and **also serves as the Polish & Harden gate** by re-running the full test suite, full lint, performance smoke, and the release-review skill before a tag is cut. If anything regresses, the release does not ship. See `.supergoal/phases/phase-13.md`.
