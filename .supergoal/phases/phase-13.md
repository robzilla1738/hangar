SUPERGOAL_PHASE_START
Phase: 13 of 13 — Distribute (sign + notarize + release)
Task: Build a universal Release binary, codesign with Developer ID (9F2JXY8TCK), notarize via notarytool, staple, package into a branded DMG, generate Sparkle 2 appcast, tag v0.1.0, push, publish a GitHub release with the DMG + appcast, and create a Homebrew Cask formula in a separate tap repo.
Type: distribution, release
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' -configuration Release -archivePath build/Hangar.xcarchive archive, ./scripts/notarize.sh, ./scripts/build-dmg.sh, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 16
Evidence required: GitHub release URL, signed DMG SHA-256, notarization ticket UUID, brew cask installability verified
Depends on phases: 12

## Why

A v0.1 nobody can download is vapor. This phase converts everything to a thing the user can `brew install --cask hangar`, drag to Applications, and use as their default terminal. This is the only phase that produces the artifact the user actually receives.

## Work

- Generate Sparkle 2 EdDSA keys via `generate_keys` (Sparkle bundle script); store private key at `~/.config/hangar-secrets/sparkle_ed_private.pem`; embed the public key in `Hangar/Info.plist` as `SUPublicEDKey`. Add `~/.config/hangar-secrets/` to user's gitignore (already from Phase 1)
- Configure `Hangar/Info.plist`:
  - `SUFeedURL` = `https://github.com/robzilla1738/hangar/releases.atom` (or hosted `appcast.xml` if Atom doesn't fit Sparkle format — use a generated appcast.xml uploaded as release asset)
  - `SUEnableAutomaticChecks` = YES
  - `SUScheduledCheckInterval` = 86400
- Add Sparkle's `XPCService` targets to the project if Sparkle 2 requires them (verify via Context7)
- `scripts/build-release.sh`:
  - `xcodebuild archive` with `-configuration Release -arch arm64 -arch x86_64` (universal)
  - Export `.app` from archive via `xcodebuild -exportArchive` with an `exportOptions.plist` that selects Developer ID Application identity `9F2JXY8TCK`
  - Verify codesign: `codesign --verify --deep --strict --verbose=2 build/Hangar.app`
- `scripts/notarize.sh`:
  - Zip the `.app`
  - `xcrun notarytool submit Hangar.zip --keychain-profile "AC_PASSWORD" --wait`
  - `xcrun stapler staple build/Hangar.app`
  - Verify staple: `xcrun stapler validate build/Hangar.app`
  - Document required environment: `notarytool store-credentials AC_PASSWORD --apple-id <ID> --team-id 9F2JXY8TCK --password <app-specific-password>` (user runs this once; document in CONTRIBUTING.md)
- `scripts/build-dmg.sh`:
  - Use `create-dmg` (Homebrew); branded background at `assets/dmg-background.png` (1000×600); volume icon at `assets/volume-icon.icns`
  - Layout: Hangar.app on the left, /Applications symlink on the right
  - Output: `dist/Hangar-0.1.0.dmg`
  - Codesign the DMG: `codesign --sign "Developer ID Application: Robert Courson (9F2JXY8TCK)" dist/Hangar-0.1.0.dmg`
  - Notarize+staple the DMG (some users prefer this; do it for safety)
  - SHA-256: `shasum -a 256 dist/Hangar-0.1.0.dmg` → record in release notes
- `scripts/build-appcast.sh`:
  - Generate `dist/appcast.xml` using Sparkle's `generate_appcast` against `dist/`; sign with the EdDSA private key
- `.github/workflows/release.yml` (full impl this phase):
  - Trigger: `on: push: tags: ['v*.*.*']`
  - Runner: `macos-26`
  - Steps:
    1. Checkout (with submodules)
    2. Import Developer ID cert from `secrets.APPLE_DEVELOPER_ID_CERT_P12_BASE64` + `secrets.APPLE_DEVELOPER_ID_CERT_PASSWORD`
    3. Store notarytool credentials from secrets
    4. Run `scripts/build-release.sh`
    5. Run `scripts/notarize.sh`
    6. Run `scripts/build-dmg.sh`
    7. Run `scripts/build-appcast.sh`
    8. Upload `Hangar-0.1.0.dmg` and `appcast.xml` as release assets via `gh release create`
    9. Write the release body from `CHANGELOG.md` `[0.1.0]` section
  - Required secrets enumerated in `.github/secrets-checklist.md`
- Update `CHANGELOG.md` with `[0.1.0] - 2026-05-16` and the full feature list (multi-pane, agent profiles, approval inbox, mission control, cost pill, worktrees, diff sidecar, polish/themes, hardening)
- Tag `v0.1.0`, push, watch the release workflow succeed
- Create the Homebrew tap repo via `gh repo create robzilla1738/homebrew-hangar --public --description "Homebrew Cask tap for Hangar"`:
  - `Casks/hangar.rb` formula:
    ```ruby
    cask "hangar" do
      version "0.1.0"
      sha256 "<sha-from-release>"
      url "https://github.com/robzilla1738/hangar/releases/download/v0.1.0/Hangar-0.1.0.dmg"
      name "Hangar"
      desc "Native macOS terminal for managing agentic CLI workflows"
      homepage "https://github.com/robzilla1738/hangar"
      depends_on macos: ">= :tahoe"
      app "Hangar.app"
      zap trash: [
        "~/Library/Application Support/Hangar",
        "~/Library/Preferences/dev.robcourson.hangar.plist",
        "~/Library/Caches/dev.robcourson.hangar",
        "~/.config/hangar"
      ]
    end
    ```
- Update README install section: `brew install --cask robzilla1738/hangar/hangar` (after tap is published) and a direct DMG download badge
- Smoke install on this Mac: `brew tap robzilla1738/hangar`, `brew install --cask hangar`, drag from Applications, verify launch, verify Sparkle finds no update for the just-released version

## Acceptance criteria (all must pass — verify each in transcript)

- `~/.config/hangar-secrets/sparkle_ed_private.pem` exists; `Info.plist` SUPublicEDKey is set
- Universal binary verified: `lipo -info build/Hangar.app/Contents/MacOS/Hangar` lists `arm64 x86_64`
- Codesign verify exits 0: `codesign --verify --deep --strict --verbose=2 build/Hangar.app`
- Notarization succeeds; notarytool returns `status: Accepted` with a ticket UUID
- `stapler validate` on the .app exits 0
- DMG built at `dist/Hangar-0.1.0.dmg`; size < 30 MB
- DMG is codesigned and notarized/stapled
- `appcast.xml` generated and EdDSA-signed
- GitHub Actions release workflow ran on tag `v0.1.0` and completed successfully (`gh run list --workflow=release.yml --limit 1` shows conclusion `success`)
- GitHub release `v0.1.0` exists with assets `Hangar-0.1.0.dmg` and `appcast.xml`
- Release notes include the v0.1.0 feature list pulled from CHANGELOG
- Homebrew tap repo `robzilla1738/homebrew-hangar` exists and contains `Casks/hangar.rb` with the correct SHA-256
- `brew tap robzilla1738/hangar` followed by `brew install --cask hangar` succeeds on this machine (or, if cert flow has not been finalized for the live install, output of `brew cask audit Casks/hangar.rb` from the tap is clean)
- Launching the installed Hangar.app produces a working window (cold-launch smoke)
- Sparkle check ("Check for Updates…") with the just-installed version reports "You're up to date." against the live appcast
- README install section updated and renders correctly on github.com

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `bash scripts/build-release.sh`
- `bash scripts/notarize.sh`
- `bash scripts/build-dmg.sh`
- `bash scripts/build-appcast.sh`
- `gh release create v0.1.0 dist/Hangar-0.1.0.dmg dist/appcast.xml --title "Hangar v0.1.0" --notes-file release-notes-0.1.0.md`
- `brew tap robzilla1738/hangar && brew install --cask hangar`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listings of `scripts/`, `dist/`, the tap repo's `Casks/`
- Codesign + stapler verify output
- Notarization ticket UUID
- GitHub release URL
- `brew install` output last 10 lines
- Demo screenshot of the installed app launched fresh from /Applications: `.supergoal/evidence/phase-13-installed.png`
- SHA-256 of the DMG (must match the one in the cask formula)

## Notes

- Consult `release-review` skill (one more pass) before the tag actually gets pushed.
- If the `notarytool` step requires the user's app-specific password and it isn't yet stored, surface the exact `notarytool store-credentials` command and stop — per `feedback_dont_run_generators`, don't loop.
- Homebrew Cask formula style: read the cask Style Guide for current 2026 conventions (Context7 / brew docs).
- The release workflow uses GitHub Secrets. The user needs to add:
  - `APPLE_DEVELOPER_ID_CERT_P12_BASE64` (the .p12 export of the Developer ID cert + private key, base64-encoded)
  - `APPLE_DEVELOPER_ID_CERT_PASSWORD`
  - `APPLE_ID` (apple ID email)
  - `APPLE_TEAM_ID` = `9F2JXY8TCK`
  - `APPLE_APP_SPECIFIC_PASSWORD`
  - `SPARKLE_ED_PRIVATE_KEY_BASE64`
  Document these in `.github/secrets-checklist.md` and surface a clear "add these secrets in repo settings, then re-trigger the workflow" message if any are missing on the first tag push.
- Memory writeback: save `project_hangar.md` UPDATE — write the actual release URL, the DMG SHA-256, and the v0.1.0 ship date into the existing memory; mark Hangar as `shipped: v0.1.0`.
- Memory writeback: save `reference_macos_release_pipeline_2026.md` with the exact notarytool / stapler / Sparkle 2 / Cask incantations that worked, so the next macOS app release run starts faster.
