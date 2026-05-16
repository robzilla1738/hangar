# Hangar

> Native macOS terminal for agentic CLI workflows.

[![CI](https://github.com/robzilla1738/hangar/actions/workflows/ci.yml/badge.svg)](https://github.com/robzilla1738/hangar/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS 26+](https://img.shields.io/badge/macOS-26%20Tahoe%2B-blue)](https://www.apple.com/macos)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](https://www.swift.org)

![Hangar hero](docs/screenshots/hero.png)

What Ghostty is for terminal craft, Hangar is for agent orchestration. Built around the way developers actually use Claude Code, Codex CLI, Hermes, and friends — multi-pane, approval-aware, diff-aware, cost-aware. Native macOS. No Electron, no JS runtime, no cloud account.

## Why Hangar

- **Mission Control for agents.** `Cmd-0` zooms out to a glanceable grid of every agent across every window.
- **Unified Approval Inbox.** Every "agent wants to run X" routes to one inbox with macOS notifications. No more silent waits.
- **Diff sidecar.** Files an agent touches show up live in a Sublime-Merge-style sidecar.
- **Cost pill.** Today's spend always visible in the title bar. Click to drill down by agent, project, model.
- **Worktree shelves.** `Cmd-Shift-W` spawns a git worktree so agents stop colliding on the same checkout.
- **Native polish.** Liquid Glass surfaces, real macOS menus, Ghostty-grade speed.

## Install

### Homebrew Cask (recommended)

```bash
brew tap robzilla1738/hangar
brew install --cask hangar
```

### Direct download

Grab the latest signed/notarized `Hangar-x.y.z.dmg` from [Releases](https://github.com/robzilla1738/hangar/releases/latest) → drag to `/Applications`.

### Requirements

- macOS 26 Tahoe or later
- Apple Silicon or Intel
- For agent features: `claude`, `codex`, and/or `hermes` on `$PATH` (Hangar auto-detects)

## Features (v0.1)

| Feature | Status |
|---|---|
| Multi-pane terminal (splits, tabs, projects) | ✅ |
| Auto-detect Claude Code / Codex CLI / Hermes | ✅ |
| Status pill per pane | ✅ |
| Unified Approval Inbox + notifications | ✅ |
| Mission Control grid (Cmd-0) | ✅ |
| Cost pill + breakdown sheet | ✅ |
| JSON5 config with hot reload | ✅ |
| Worktree shelf (Cmd-Shift-W) | ✅ |
| Diff sidecar (FSEvents) | ✅ |
| Liquid Glass theming | ✅ |
| Voice (Whisper dictation) | ⏳ v0.2 |
| Replay timeline | ⏳ v0.2 |
| MCP control plane drawer | ⏳ v0.2 |
| `@`-routing between agents | ⏳ v0.2 |
| Prompt fan-out | ⏳ v0.2 |
| Semantic history | ⏳ v0.2 |

## Build from source

```bash
git clone https://github.com/robzilla1738/hangar.git
cd hangar
brew install xcodegen swiftlint xcbeautify swift-format
xcodegen generate
xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify
xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify
```

Open `Hangar.xcodeproj` in Xcode 26+ for development.

## Configuration

Hangar generates `~/.config/hangar/config.json5` on first launch. Edit it; changes hot-reload. See [`docs/config.md`](docs/config.md) for the full schema.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues, PRs, and agent-compatibility reports welcome.

## License

[MIT](LICENSE) © Robert Courson and Hangar contributors.

## Acknowledgements

- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) — terminal emulator backbone for v0.1 (we plan to swap to [libghostty](https://github.com/ghostty-org/ghostty) in v0.2).
- [GRDB.swift](https://github.com/groue/GRDB.swift) — SQLite layer.
- [Sparkle](https://sparkle-project.org/) — auto-update.
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/) — bundled font under SIL OFL.
