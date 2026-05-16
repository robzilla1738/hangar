# Hangar 0.1.0

Native macOS terminal for managing agentic CLI workflows.

## Install

```bash
brew tap robzilla1738/hangar
brew install --cask hangar
```

Or grab `Hangar-0.1.0.dmg` from this release directly and drag to `/Applications`.

**Requirements:** macOS 15 Sequoia or later (macOS 26 Tahoe recommended for full Liquid Glass surfaces).

## What's in this release

This is the **v0.1 foundation** of Hangar. The full architecture is laid down (multi-pane terminal, agent profiles for Claude Code / Codex CLI / Hermes, Approval Inbox, Mission Control grid, cost ledger, worktree shelf, diff sidecar, theme system, Keychain integration). Several feature surfaces (Cmd-0 wiring, live PID detection, breakdown sheet, FSEventStream callbacks) are scaffolded with stable APIs but ship their UI wiring in a v0.1.x point release.

### Foundation
- Xcode + SwiftPM hybrid project (Hangar app target + HangarCore + HangarKit modules)
- Swift 6.2 strict concurrency throughout
- Universal binary, Developer ID signed, notarized, stapled
- CI on every push (macos-15, Xcode 16, build + test + lint)
- 75 unit tests pass

### Core surfaces
- **Multi-pane terminal** via SwiftTerm with split (`⌘D`/`⌘⇧D`) and close (`⌘W`) wired
- **JSON5 config** at `~/.config/hangar/config.json5` with file-watcher hot reload
- **Agent profile system** with Claude Code, Codex CLI, Hermes, and Raw Shell built-ins; per-profile approval-prompt regex
- **Approval Inbox actor** routes `y`/`n`/`a` back to the originating pane; macOS notification category registered with three action buttons
- **Status pill, model badge, attention dot** components
- **Mission Control overlay** + sorter (attention-first then status priority)
- **Cost ledger** with daily/monthly totals + breakdown by provider/agent/model; **pricing table** snapshotted 2026-05 for Anthropic / OpenAI / Nous models
- **GitService** for worktree management (list/create/remove with porcelain-v2 parser)
- **Diff sidecar** with FSEvents-style watcher + CollectionDifference-based line diff
- **Theme system** with Hangar Dark + Hangar Light tokens
- **Keychain** wrapper for provider API keys (used by cost reconciler in v0.2)

### Hardening
- Hardened-runtime entitlements: JIT, library-validation disabled, dyld env vars
- No App Sandbox (terminals can't sandbox practically)
- Sparkle 2 wired into the app bundle (XPC services validated)
- VoiceOver checklist + security review notes shipped in `docs/`

## Known scope (v0.2+)

The following features are designed and have stable APIs in place but ship their UI/integration in v0.1.x point releases:

- `⌘0` keystroke for Mission Control (sorter + overlay components ready)
- `⌘⇧A` global hotkey (Approval Inbox actor + popover ready)
- Live PID walking via `libproc` (binary-name resolver ready)
- Cost breakdown sheet (CostBreakdown type + Swift Charts integration designed)
- Worktree create sheet + click-to-jump (GitService ready)
- FSEventStream callback path (polling impl ships now; API identical for swap)
- Liquid Glass material application across chrome surfaces (theme tokens ready)
- 6 marketing screenshots (placeholders in `docs/screenshots/`)

See [v0.2 roadmap](https://github.com/robzilla1738/hangar/issues?q=label%3Av0.2) for the full deferral list with linked issues.

## Verifying the download

```bash
shasum -a 256 Hangar-0.1.0.dmg
# 6252dd4204974a4204653b4e8c9831ba684afa302a61691f9a66dcd00b6b6b9b
```

Signed and notarized by Apple under Developer ID `9F2JXY8TCK` (Robert Courson).

## Acknowledgements

[SwiftTerm](https://github.com/migueldeicaza/SwiftTerm), [GRDB.swift](https://github.com/groue/GRDB.swift), [Sparkle](https://sparkle-project.org/).

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
