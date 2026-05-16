SUPERGOAL_PHASE_START
Phase: 1 of 13 — Bootstrap repo + project + CI
Task: Initialize the Hangar repo, Xcode project, two SPM modules (HangarCore, HangarKit), tooling configs, and a green CI pipeline on a public GitHub repo at robzilla1738/hangar.
Type: greenfield, foundation
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 14
Evidence required: gh repo view output, xcodebuild build last 10 lines + exit code, xcodebuild test last 10 lines + exit code, swiftlint output, swift-format lint output, CI workflow run URL, tree -L 2 of repo
Depends on phases: none

## Why

Every later phase depends on a green-building project skeleton and a public repo with CI. Without this, no phase can verify.

## Work

- Initialize git repo at `/Users/robert/Code/terminal` (default branch `main`)
- Create public GitHub repo `robzilla1738/hangar` via `gh repo create` and set as origin
- Create Xcode project `Hangar.xcodeproj` at root with target `Hangar` (macOS app, SwiftUI lifecycle, Swift 6 strict concurrency)
  - Minimum deployment: macOS 26.0
  - Bundle identifier: `dev.robcourson.hangar`
  - Display name: `Hangar`
  - Team ID: `9F2JXY8TCK`
  - Hardened runtime: ON with entitlements `com.apple.security.cs.allow-jit` + `com.apple.security.cs.disable-library-validation`
  - App Sandbox: OFF
- Create Swift Package at root with two library products via `Package.swift`:
  - `HangarCore` — non-UI logic (process, config, db, agents, costs, git)
  - `HangarKit` — SwiftUI components, theme, layouts
- Link both packages into the Hangar app target
- Add dependencies in `Package.swift`:
  - SwiftTerm 1.x (`https://github.com/migueldeicaza/SwiftTerm`)
  - GRDB.swift 7.x (`https://github.com/groue/GRDB.swift`)
  - Sparkle 2.x (`https://github.com/sparkle-project/Sparkle`)
- Install dev tooling via Homebrew: `swiftlint`, `swift-format` (system PATH; user has `/Users/robert/depot_tools/swift-format` — add to PATH or `brew install swift-format`), `xcbeautify`, `create-dmg`
- Write `.swiftlint.yml` with strict rules (no_force_cast, no_force_try, line_length 120, function_body_length 60, file_length 500)
- Write `.swift-format.json` with 4-space indent, line length 120, respect existing line breaks
- Write `.editorconfig`, `.gitattributes`, `.gitignore` (include Xcode `*.xcuserdata`, `*.xcuserstate`, `DerivedData`, `.swiftpm`, `.DS_Store`, `~/.config/hangar-secrets`)
- Write `LICENSE` (MIT, copyright "2026 Robert Courson and Hangar contributors")
- Write `README.md` skeleton: tagline, hero screenshot placeholder, install (brew cask + DMG), feature list (✓ working, ⏳ planned), build-from-source, license badge, CI badge
- Write `CONTRIBUTING.md`: dev setup, Conventional Commits, PR checklist
- Write `CHANGELOG.md` (Keep-a-Changelog format, `[Unreleased]` section)
- Write `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1)
- Write `SECURITY.md` (vulnerability reporting via email)
- Add `.github/ISSUE_TEMPLATE/bug_report.yml`, `feature_request.yml`, `agent_compat.yml`
- Add `.github/PULL_REQUEST_TEMPLATE.md`
- Add `.github/workflows/ci.yml` — on push/PR to main: macos-26 runner, `xcodebuild build`, `xcodebuild test`, `swiftlint`, `swift-format lint`
- Add `.github/workflows/release.yml` — on `v*.*.*` tag, build/sign/notarize/publish (full impl in Phase 13; stub for now with `echo "release workflow"`)
- Initial commit ("chore: bootstrap Hangar v0.1 scaffolding") and push to `origin/main`
- Verify CI run via `gh run list` and `gh run view`

## Acceptance criteria (all must pass — verify each in transcript)

- `git remote -v` shows `origin = git@github.com:robzilla1738/hangar.git` (or https equivalent) and `gh repo view robzilla1738/hangar` exit 0
- `tree -L 2 .` shows: `Hangar.xcodeproj/`, `Package.swift`, `Sources/HangarCore/`, `Sources/HangarKit/`, `Tests/HangarCoreTests/`, `Tests/HangarKitTests/`, `Hangar/` (app target sources), `.github/`, `LICENSE`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.swiftlint.yml`, `.swift-format.json`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' build` exits 0
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test` exits 0 with at least one trivial test passing in each module (HangarCoreTests, HangarKitTests, HangarTests)
- `swiftlint --strict` exits 0
- `swift-format lint --recursive --strict Sources Tests Hangar` exits 0
- Bundle identifier in `Hangar.xcodeproj` is `dev.robcourson.hangar`
- Deployment target is `macOS 26.0` (verifiable via `xcodebuild -showBuildSettings -scheme Hangar | grep MACOSX_DEPLOYMENT_TARGET`)
- Hardened runtime entitlements file exists at `Hangar/Hangar.entitlements` and contains `com.apple.security.cs.allow-jit` and `com.apple.security.cs.disable-library-validation`
- `Package.swift` declares SwiftTerm, GRDB.swift, and Sparkle as dependencies
- `.gitignore` excludes `DerivedData/`, `.swiftpm/`, `*.xcuserdata*`, `.DS_Store`
- `README.md` exists, contains tagline "Native macOS terminal for agentic CLI workflows", and at least the install + feature stub sections
- `LICENSE` is MIT with current year (2026) and "Robert Courson and Hangar contributors"
- CI workflow `ci.yml` ran successfully on the initial commit — `gh run list --workflow=ci.yml --limit 1` shows status `completed` and conclusion `success`

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`
- `gh run list --workflow=ci.yml --limit 1`

## Evidence required in transcript

- `gh repo view robzilla1738/hangar --json url,visibility,isPrivate` output
- `tree -L 2 .` output (or `find . -maxdepth 2 -not -path './.git/*' -not -path './DerivedData*'`)
- Build command last 10 lines + exit code
- Test command last 10 lines + exit code (one passing test minimum per module)
- Lint commands last 5 lines each + exit code
- CI run URL from `gh run view --json url --jq .url`

## Notes

- Consult the `macos` and `swift` skills during this phase for Swift 6 strict concurrency setup, SPM/Xcode hybrid layout best practice, and entitlements.
- Use Context7 to verify SwiftTerm, GRDB.swift, and Sparkle 2 current SPM URLs and version compatibility with Swift 6.2 / macOS 26 before locking versions.
- If `swiftlint` or `xcbeautify` is missing, `brew install swiftlint xcbeautify create-dmg` first. If `swift-format` is on `/Users/robert/depot_tools/swift-format` (per recon), either use that absolute path in commands or `brew install swift-format` to get a PATH-resolvable copy.
- Initial trivial tests can be `XCTAssertTrue(true)` placeholders — real tests arrive in later phases. The point of Phase 1 is the green pipeline.
- Use `gh repo create robzilla1738/hangar --public --source=. --remote=origin --description "Native macOS terminal for managing agentic CLI workflows"` to scaffold the remote in one shot.
- Memory writeback target: write a `reference_hangar_bootstrap.md` if any Xcode 26 / SPM-in-Xcode-26 quirk is discovered worth recording.
