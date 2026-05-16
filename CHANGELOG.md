# Changelog

All notable changes to Hangar are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Hangar follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.1] — 2026-05-16

### Fixed

- **Terminal now renders on launch.** v0.1.0 shipped with a broken view hierarchy where the SwiftTerm NSView never appeared and the window opened empty. Fixed by wrapping the terminal NSView in a `TerminalHostView` container that pins the child to its bounds and grabs first responder when the window appears, so keystrokes are accepted immediately.
- Clean Ghostty-style window chrome: transparent title bar, traffic lights have their own strip, terminal sits in a padded content area below.
- Window opens at a sensible 960×600 centered on screen rather than at the SwiftUI default.

### Added

- Initial v0.1 scaffolding: Xcode project, two SPM modules (`HangarCore`, `HangarKit`), CI pipeline, governance docs.

## [0.1.0] — TBD

First public release. See README for the full feature list.

### Added

- Multi-pane terminal (splits, tabs, projects) on top of SwiftTerm.
- Auto-detection of Claude Code, Codex CLI, and Hermes; status pill per pane.
- Unified Approval Inbox with macOS notifications and `Cmd-Shift-A` global hotkey.
- Mission Control overlay (`Cmd-0`) showing every agent across every window.
- Cost ledger in SQLite with per-profile token parsers; title-bar cost pill with breakdown sheet.
- JSON5 configuration at `~/.config/hangar/config.json5` with file-watcher hot reload.
- Worktree shelf with `Cmd-Shift-W` create and click-to-jump.
- Diff sidecar driven by FSEvents.
- Two built-in themes (Hangar Dark, Hangar Light) with Liquid Glass surfaces.
- Hardened-runtime universal binary, signed/notarized, distributed via GitHub Releases + Homebrew Cask tap.

[Unreleased]: https://github.com/robzilla1738/hangar/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/robzilla1738/hangar/releases/tag/v0.1.0
