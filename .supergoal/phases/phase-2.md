SUPERGOAL_PHASE_START
Phase: 2 of 9 — B · Title-bar overlay + AppState registry
Task: Add a custom `WindowOverlayBar` at the top of every Hangar window's content view showing pane title + model badge (left), StatusPill bound to the active pane (center), CostPill + ApprovalInboxBell + Mission Control button (right). Add an AppState `openWindows` registry windows register against, plus shared `ApprovalInbox` and `CostLedger` instances.
Type: brownfield, ui, integration
Mandatory commands: swift test, xcodebuild build, xcodebuild test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 10
Evidence required: build/test exit codes, lints clean, screenshot of a Hangar window showing the overlay bar with CostPill ($0.00) + Bell (0) + Mission Control button visible, screenshot with `claude` running showing the model badge populated
Depends on phases: 1

## Why

This is the first phase that produces visibly different chrome. The overlay is the host for every downstream indicator (cost, approvals, status, mission control).

## Work

- Add `Sources/HangarKit/Chrome/WindowOverlayBar.swift`:
  - `WindowOverlayBar` SwiftUI view, fixed height ~36pt
  - Left cluster: pane title (Text) + model badge (small capsule, only when `model != nil`)
  - Center cluster: `StatusPill(status:agentName:)`
  - Right cluster: `CostPill` + `ApprovalInboxBell` + Mission Control `Button { systemImage: "rectangle.grid.2x2" }`
  - Material: `.thinMaterial` background with `.bottom` border separator
  - Reads from `@Environment(AppState.self)` for shared inbox + ledger + active pane id

- Extend `AppState` (`Hangar/HangarApp.swift`):
  - `var openWindows: [UUID: WindowViewModel] = [:]` (keyed by window UUID)
  - `let approvalInbox: ApprovalInbox` (constructed with a PaneInputSink that looks up the originating pane by id via the registry)
  - `let costLedger: CostLedger`
  - `var todayCostUSD: Double = 0.0` (updated by a task subscribed to costLedger event stream)
  - `var pendingApprovalCount: Int = 0` (updated from inbox.updates)
  - `func registerWindow(_:)` / `func unregisterWindow(_:)`
  - `func writeToPane(_ paneID: UUID, _ text: String)` — looks up the pane across all open windows and writes via `paneVM.emulator.send(_:)`

- Update `WindowRootView` (`Sources/HangarKit/Layout/WindowRootView.swift`):
  - Layout becomes `VStack(spacing: 0) { WindowOverlayBar(...); existing pane tree }`
  - Reduce the existing top padding (28pt) since the overlay bar provides the spacing now
  - Pass active-pane PaneViewModel to the overlay bar via the binding

- Update `Hangar/ContentView.swift`:
  - On `.task`, register the WindowViewModel with AppState; on disappear, unregister
  - Inject AppState via `.environment(appState)` (already in HangarApp)

- Tests under `Tests/HangarKitTests/Chrome/`:
  - `WindowOverlayBarTests` (`@MainActor`) — instantiation with various states (no agent, agent detected, awaiting approval, cost > 0)

- Tests under `Tests/HangarCoreTests/`:
  - `AppStateRegistryTests` (`@MainActor`) — register/unregister; writeToPane finds the right pane

## Acceptance criteria

- WindowOverlayBar.swift exists and renders the three clusters
- AppState exposes openWindows, approvalInbox, costLedger, todayCostUSD, pendingApprovalCount, registerWindow/unregisterWindow/writeToPane
- WindowRootView includes the overlay bar at the top
- ContentView registers + unregisters the WindowViewModel on appear/disappear
- WindowOverlayBarTests + AppStateRegistryTests cover the documented behaviors (5+ tests total)
- xcodebuild build exits 0
- swift test exits 0
- xcodebuild test exits 0
- swiftlint + swift-format both exit 0
- Smoke screenshots committed at `.supergoal/evidence/phase-2-overlay-empty.png` and `.supergoal/evidence/phase-2-overlay-with-claude.png` (both visibly show the overlay bar; the second shows the model badge populated)

## Mandatory commands

- `swift test`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `/opt/homebrew/bin/swift-format lint --recursive --strict Sources Tests Hangar`
- Smoke: `osascript -e 'tell application "Hangar" to activate' && sleep 2 && screencapture -x -l$(osascript -e 'tell application "Hangar" to id of window 1') .supergoal/evidence/phase-2-overlay-empty.png`

## Evidence required

- File listing of new files
- Build/test/lint output tails
- Both smoke screenshots committed

## Notes

- Keep the overlay bar trivial — no animations, no hover effects yet. Phase H/I polish if there's time.
- Mission Control button is a stub action in phase B; phase E wires the actual overlay open.
- ApprovalInboxBell already exists as a component; just bind it.
- CostPill takes `todayUSD:warnAtUSD:hardStopAtUSD:onTap:` — bind to AppState.todayCostUSD and AppState.config.costs.
