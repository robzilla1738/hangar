SUPERGOAL_PHASE_START
Phase: 9 of 9 — I · Polish + ship v0.2.0
Task: Bump version to 0.2.0; update CHANGELOG with the agent-orchestration story; archive + sign + notarize + staple universal Hangar.app + DMG; tag v0.2.0; create the GitHub release with DMG attached; bump the Homebrew cask and push the tap.
Type: distribution, release
Mandatory commands: xcodebuild build, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar, bash scripts/release/build-release.sh, bash scripts/release/notarize.sh, bash scripts/release/build-dmg.sh
Acceptance criteria: 14
Evidence required: release URL; DMG SHA-256 matching cask; notarization ticket IDs; `brew upgrade --cask hangar` verified locally
Depends on phases: 1-8

## Why

A v0.2 that nobody can download is vapor. This phase converts every prior phase's work into a thing the user can `brew upgrade --cask hangar` to get.

## Work

- Bump version in `project.yml`:
  - `MARKETING_VERSION: "0.2.0"`
  - `CURRENT_PROJECT_VERSION: "3"`
- Update `Sources/HangarCore/HangarCore.swift`: `version = "0.2.0"`; `buildIdentifier = "v0.2.0"`
- Update `Tests/HangarKitTests/HangarKitTests.swift` version assertion to `"0.2.0"`
- CHANGELOG `[0.2.0]` section — full agent-orchestration story:
  - Title-bar overlay with model badge + status pill + cost pill + approval bell + Mission Control
  - Output-stream → agent profile detection
  - Approval inbox routes prompts; macOS notifications; Cmd-Shift-A popover
  - Cost ledger live
  - Mission Control (Cmd-0)
  - Left sidebar (Cmd-Shift-S) with projects + worktrees; Cmd-Shift-W new-worktree sheet
  - Right sidecar (Cmd-Option-D) with live file diffs
  - Terminal table-stakes (tabs, font sizing, find, clear, URL Cmd-click, drag-folder, restore-last-state)

- Run the release pipeline (reuse v0.1.1 scripts):
  - `xcodegen generate`
  - `xcodebuild archive` Release universal
  - `xcodebuild -exportArchive`
  - `ditto -c -k ... | xcrun notarytool submit --keychain-profile AC_PASSWORD --wait`
  - `xcrun stapler staple build/export/Hangar.app`
  - `create-dmg ... dist/Hangar-0.2.0.dmg`
  - `codesign --sign "Developer ID Application: Robert Courson (9F2JXY8TCK)" --options runtime --timestamp dist/Hangar-0.2.0.dmg`
  - `xcrun notarytool submit dist/Hangar-0.2.0.dmg --keychain-profile AC_PASSWORD --wait`
  - `xcrun stapler staple dist/Hangar-0.2.0.dmg`
  - `shasum -a 256 dist/Hangar-0.2.0.dmg` → record

- Tag and release:
  - `git tag -a v0.2.0 -m "Hangar 0.2.0 — visible agent orchestration"`
  - `git push origin main`
  - `git push origin v0.2.0`
  - `gh release create v0.2.0 dist/Hangar-0.2.0.dmg --title "Hangar v0.2.0" --notes-file release-notes-0.2.0.md`

- Homebrew Cask update:
  - In `/tmp/homebrew-hangar` (or a clean clone): update `Casks/hangar.rb` version + SHA-256
  - Commit + push
  - Verify with `brew update && brew upgrade --cask hangar` on this machine

- Replace `/Applications/Hangar.app` with the freshly notarized build and confirm `brew info --cask hangar` shows 0.2.0

## Acceptance criteria

- project.yml MARKETING_VERSION is 0.2.0
- HangarCore.version returns "0.2.0"
- HangarKitTests version assertion updated and passes
- CHANGELOG `[0.2.0]` section lists every feature shipped in phases A-H
- Universal Release .app built (`lipo -info` shows arm64 + x86_64)
- .app codesign verify exits 0
- .app notarization status Accepted; stapler validate green
- DMG built at `dist/Hangar-0.2.0.dmg`
- DMG notarization status Accepted; stapler validate green
- DMG SHA-256 captured to dist/Hangar-0.2.0.dmg.sha256
- GitHub release v0.2.0 exists with DMG asset (verifiable via `gh release view v0.2.0`)
- Homebrew cask updated to 0.2.0 with the correct SHA-256
- `brew info --cask hangar` shows 0.2.0
- `/Applications/Hangar.app` runs the new build (verifiable via Hangar > About showing 0.2.0)

## Mandatory commands

- `swift test`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' -configuration Release archive -archivePath build/Hangar.xcarchive ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO`
- `xcodebuild -exportArchive -archivePath build/Hangar.xcarchive -exportPath build/export -exportOptionsPlist scripts/release/ExportOptions.plist`
- `xcrun notarytool submit ... --keychain-profile AC_PASSWORD --wait --output-format json`
- `xcrun stapler staple build/export/Hangar.app`
- `xcrun stapler staple dist/Hangar-0.2.0.dmg`
- `gh release create v0.2.0 dist/Hangar-0.2.0.dmg ...`

## Evidence required

- Notarization ticket IDs for .app + DMG
- DMG SHA-256
- GitHub release URL
- `gh release view v0.2.0 --json url,assets`
- Brew install log showing 0.2.0
- About-panel screenshot showing 0.2.0

## Notes

- If notarytool credentials need refreshing: stop and surface `xcrun notarytool store-credentials AC_PASSWORD ...` per feedback_dont_run_generators
- The cask SHA must exactly match the DMG SHA; mismatch = brew install fails verification
