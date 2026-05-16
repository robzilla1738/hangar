# Contributing to Hangar

Thanks for considering a contribution. Hangar is small, opinionated, and built around a tight UX. Read this before opening a PR.

## Dev setup

```bash
git clone https://github.com/robzilla1738/hangar.git
cd hangar
brew install xcodegen swiftlint xcbeautify swift-format create-dmg
xcodegen generate
open Hangar.xcodeproj
```

Requires Xcode 26+ with the macOS 26.2 SDK.

## Commit style

[Conventional Commits](https://www.conventionalcommits.org/). Common types:

- `feat:` — new user-facing feature
- `fix:` — bug fix
- `perf:` — perf improvement
- `refactor:` — non-behavior code change
- `docs:` — documentation only
- `test:` — tests only
- `chore:` — tooling/config/CI changes
- `style:` — formatting/lint changes (no behavior)

Example: `feat(approval-inbox): add Cmd-Shift-A global hotkey`

## PR checklist

- [ ] Branch off `main`
- [ ] `xcodebuild build` passes
- [ ] `xcodebuild test` passes (add tests if you touch logic)
- [ ] `swiftlint --strict` passes
- [ ] `swift-format lint --recursive --strict Sources Tests Hangar` passes
- [ ] No new TODOs without a linked issue
- [ ] Screenshots attached if you changed UI
- [ ] CHANGELOG.md updated under `[Unreleased]`

## Architecture

- `HangarCore` — Swift Package, non-UI logic (terminal, processes, config, agents, costs, persistence, git)
- `HangarKit` — Swift Package, SwiftUI components, themes, layouts
- `Hangar` — Xcode app target, glue (HangarApp, menus, AppKit bridges, entitlements)

Both packages are built with **Swift 6 strict concurrency**. New `@unchecked Sendable` needs justification.

## Agent compatibility

If you find an agent CLI that Hangar mis-detects (wrong profile) or whose approval prompts aren't caught, please open an [agent_compat issue](https://github.com/robzilla1738/hangar/issues/new?template=agent_compat.yml) with a recorded fixture (`script -q -t 0 fixture.ansi`).

## Code of Conduct

This project follows the [Contributor Covenant 2.1](CODE_OF_CONDUCT.md). Be kind.

## Releases

Tag `v*.*.*` on `main`. The release workflow builds → signs → notarizes → publishes the DMG + appcast. See `.github/workflows/release.yml`.
