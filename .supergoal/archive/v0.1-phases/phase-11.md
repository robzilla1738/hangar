SUPERGOAL_PHASE_START
Phase: 11 of 13 — Polish (Liquid Glass + themes + visuals + states)
Task: Apply Liquid Glass chrome across every Hangar surface, ship two built-in themes (Hangar Dark, Hangar Light), implement empty/loading/error states for every panel, refine motion/animations, and commit a full set of marketing-quality screenshots to the repo.
Type: greenfield, ui, polish
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 14
Evidence required: build/test exit codes, full screenshot set in docs/screenshots/, themed comparison screenshots, accessibility contrast check
Depends on phases: 2-10

## Why

This is the "indistinguishable from an Apple-made app" gate. v0.1 will be judged on screenshots before code. The polish pass also surfaces every gap (missing empty state, awkward truncation, weird focus ring) that the implementation phases ran past.

## Work

- `Sources/HangarKit/Theme/`:
  - `Theme` — struct with all color tokens: `chromeBackground`, `paneBackground`, `paneForeground` (16 ANSI), `accent`, `divider`, `focusRing`, `statusIdle`, `statusThinking`, `statusAwaiting`, `statusErrored`, `statusDone`, `attentionDot`, `pillBackground`, `pillForeground`
  - `ThemeStore` — `@Observable`; current theme; switches based on `config.appearance.theme` and OS appearance changes
  - Two built-in themes:
    - **Hangar Dark** — deep ink chrome, off-white text, subtle violet accent, glassy surfaces with vibrancy materials behind
    - **Hangar Light** — warm paper chrome, near-black text, blue accent, frosted vibrancy
- Liquid Glass application:
  - Title bar: `NSVisualEffectView` with `.windowBackground` material + `vibrant = true`
  - Left sidebar + right sidecar: `.sidebar` material
  - Approval inbox popover, settings sheet, breakdown sheet: `.popover` / `.menu` materials
  - Mission Control overlay backdrop: `.hudWindow` material
  - Status pills + cost pill + model badges: SwiftUI `.glassEffect()` (or appropriate Liquid Glass modifier per macOS 26 Tahoe HIG)
- Motion polish (use SwiftUI phase animator + matched-geometry across these surfaces):
  - Pane focus ring: 100ms ease-in-out scale 0.99 → 1.0
  - Status pill state changes: cross-fade with 150ms duration
  - Mission Control open/close: 250ms cascade open, 200ms collapse on click
  - Approval Inbox popover present: spring(response: 0.35, damping: 0.78)
- Empty / loading / error states for every surface:
  - Approval Inbox empty: "No pending approvals."
  - Cost breakdown sheet empty: "No spend recorded yet."
  - Worktree shelf empty: "No worktrees yet — Cmd-Shift-W to create one."
  - Diff sidecar empty: "No file changes in this project."
  - Project list empty: "Open a folder to create your first project."
  - Mission Control empty (already added in Phase 7 — verify it still renders correctly with theme)
  - Loading states: shimmer placeholder for cost charts, sidecar list while FSEvents bootstraps
  - Error states: parse error banner for config, save-failed banner for projects, git command failure surfaced inline in worktree sheet
- Default app icon (placeholder):
  - Use a simple SwiftUI-rendered icon: dark gradient background, white "Hangar" wordmark in Inter or SF Display, exported via Xcode's icon generator into `Hangar/Assets.xcassets/AppIcon.appiconset` at all required sizes (16/32/64/128/256/512/1024 @1x/@2x)
- Bundled fonts:
  - SF Mono is on the system; no bundling needed
  - JetBrains Mono (Light + Regular only for v0.1) shipped in `Hangar/Resources/Fonts/` with SIL OFL license; registered via `CTFontManagerRegisterFontURLs` on launch
- Accessibility:
  - All buttons have `accessibilityLabel`
  - Status pill announces state changes via `AccessibilityNotification.announcement`
  - Contrast ≥ AA for both themes; verify via the macos `color-contrast` audit (manual check + automated test for token values)
- Screenshots committed under `docs/screenshots/`:
  - `hero.png` — main window with 3 panes (Claude / Codex / shell) + cost pill + 2 approvals in inbox
  - `mission-control.png` — overlay with 4+ tiles
  - `approval-inbox.png` — popover open with two items
  - `worktrees.png` — sidebar shelf with 3 worktrees
  - `diff-sidecar.png` — right sidecar with two file diffs
  - `theme-comparison.png` — side-by-side dark vs light
- Tests under `Tests/HangarKitTests/Theme/`:
  - `ThemeContrastTests` — assert every fg/bg token pair has WCAG AA contrast (≥ 4.5:1 for normal text)
  - `ThemeSwitchingTests` — change `config.appearance.theme`, assert `ThemeStore.current` updates

## Acceptance criteria (all must pass — verify each in transcript)

- Two built-in themes present (`hangar-dark`, `hangar-light`); switchable via Settings sheet (read-only viewer for now) AND via direct `config.appearance.theme` edit (hot-reload)
- Title bar, sidebar, sidecar, popovers all use the correct Liquid Glass materials
- Status pill / cost pill / model badge use a glass effect modifier consistent across surfaces
- Every named empty state renders the right copy
- Every named loading state shows a shimmer or progress affordance
- Every named error state surfaces the failure without crashing
- App icon set populated in `AppIcon.appiconset` and visible in Finder + Dock
- JetBrains Mono Light + Regular registered; `Hangar Settings > Font` can pick it (read-only in v0.1; user still edits config.json5)
- Six screenshots committed under `docs/screenshots/` with descriptive filenames and a `README.md` in that folder
- All theme test classes pass; theme contrast ≥ AA verified
- Switching system appearance (light/dark) updates the app theme automatically (when `theme: auto` in config; default themes set this)
- Motion durations asserted via unit tests against the SwiftUI animation primitives used: pane focus animation ≤ 150ms; Mission Control cascade open 200-500ms (already asserted in Phase 7); popover spring with response 0.30-0.40 and damping 0.70-0.85
- Build / test / lint exit 0
- README hero image (`docs/screenshots/hero.png`) referenced from `README.md`

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of `Sources/HangarKit/Theme/`, `Hangar/Resources/Fonts/`, `Hangar/Assets.xcassets/AppIcon.appiconset/`, `docs/screenshots/`
- Test output naming theme test classes
- Screenshot file paths (all six) and one paragraph confirming each is committed and renders correctly when opened with Preview
- Brief paragraph summarizing the contrast test result

## Notes

- Consult `design` skill and `macos` skill for current Liquid Glass APIs in macOS 26 (the API names and required entitlements stabilized in 26.2).
- Apple may have renamed `.glassEffect()` between betas; verify the current modifier via Context7 against the SwiftUI macOS 26.2 SDK.
- For the app icon SwiftUI-render approach, the script: render a 1024×1024 NSImage from a SwiftUI view, export via `NSBitmapImageRep.representation(using: .png)`, then resize down for the smaller variants. Doc the script under `scripts/render-app-icon.sh`.
- Screenshots can be captured via the Phase 2 smoke script extended with state setup (pre-arrange panes, then `screencapture -R` the window region).
- Save `reference_liquid_glass_materials_macos26.md` summarizing which material maps to which surface, since this changed late in the macOS 26 cycle.
