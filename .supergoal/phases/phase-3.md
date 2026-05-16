SUPERGOAL_PHASE_START
Phase: 3 of 9 — C · Approval routing end-to-end
Task: Connect each PaneViewModel's pendingApprovals stream to AppState.approvalInbox; have the bell badge reflect inbox.pendingCount; fire a macOS notification on add; bind Cmd-Shift-A to open an ApprovalInbox popover; route Approve/Deny/Approve-All clicks back through `y\n` / `n\n` / `a\n` to the originating pane via AppState.writeToPane.
Type: brownfield, ui, integration, core
Mandatory commands: swift test, xcodebuild build, xcodebuild test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 11
Evidence required: build/test/lint clean; screenshot of bell with badge ≥1 after a fake approval is fed; screenshot of popover open showing the item with Approve/Deny/Approve-All buttons; UN notification authorization log
Depends on phases: 1, 2

## Why

The headline feature. Approval prompts disappearing into a backgrounded tab is the #1 multi-agent pain — Hangar solving it is the wedge.

## Work

- In `AppState.bootstrapConfig()` (or a new `bootstrapAwareness()` step called from `.task`):
  - `await NotificationCenterService().requestAuthorization()`
  - Wire `approvalInbox = ApprovalInbox { paneID, text in await self.writeToPane(paneID, text) }`
  - Spawn a Task subscribed to `approvalInbox.updates` that updates `self.pendingApprovalCount`

- In `PaneViewModel.startObserving`:
  - When parser emits `.approvalPrompt(prompt:)`, build an `ApprovalItem(paneID: self.id, agentID: detectedAgentID ?? "unknown", prompt:)`
  - Call `await appState.approvalInbox.add(item)` (PaneViewModel holds a weak ref to AppState — set in init via the registry)
  - Call `await NotificationCenterService().notifyApproval(agentName: detectedAgentDisplayName ?? "Hangar agent", prompt: item.prompt)`

- `ApprovalInboxBell` (already in HangarKit) is bound in `WindowOverlayBar` to `appState.pendingApprovalCount` for the badge

- `ApprovalInboxView` (already in HangarKit) is presented as a `.popover(isPresented:)` attached to the bell button
- Popover items come from `appState.approvalInbox.items` (snapshot via async)
- Clicking an action button calls `await appState.approvalInbox.respond(itemID:, action:)`

- Cmd-Shift-A global keybinding via a SwiftUI Command in `HangarApp.commands`:
  - `Button("Approval Inbox") { /* toggle popover */ }.keyboardShortcut("a", modifiers: [.command, .shift])`
  - Implementation: `appState.approvalInboxPresented.toggle()` (new @Observable bool); WindowOverlayBar's bell button binds its `.popover(isPresented:)` to this

- Tests under `Tests/HangarCoreTests/Awareness/`:
  - `ApprovalRoutingEndToEndTests` — synthetic PaneViewModel + fake AppState:
    - Feed Claude approval-prompt bytes → assert inbox.items.count == 1
    - Respond .approve → assert "y\n" reached the recorded pane writes
    - Multi-pane independence (already covered in v0.1's ApprovalInboxTests; ensure not regressed)

## Acceptance criteria

- ApprovalInbox instantiation in AppState routes its sink through writeToPane
- NotificationCenterService.requestAuthorization runs once at launch
- NotificationCenterService.notifyApproval fires when items are added (verifiable via `UNUserNotificationCenter.getDeliveredNotifications` count incrementing)
- ApprovalInboxBell badge reflects appState.pendingApprovalCount in real time
- Cmd-Shift-A toggles the popover
- Approve button writes `y\n` to the originating pane (verified by a test that records pane writes)
- Deny writes `n\n`; Approve-All writes `a\n`
- Popover empty state renders when inbox is empty
- All Awareness test classes still pass (including v0.1's ApprovalInboxTests and new ApprovalRoutingEndToEndTests)
- Build/test/lint exit 0
- Smoke screenshots committed: `.supergoal/evidence/phase-3-bell-badge.png` (bell shows ≥1 badge) and `.supergoal/evidence/phase-3-popover-open.png` (popover lists the approval)

## Mandatory commands

- `swift test`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `/opt/homebrew/bin/swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required

- File listing of touched files
- Test runner output naming ApprovalRoutingEndToEndTests
- UNUserNotificationCenter authorization status logged
- Both smoke screenshots committed

## Notes

- For the smoke, you don't need a real claude approval — inject a synthetic item via a hidden Debug menu (`Hangar > Debug > Send Fake Approval`) wired in this phase. Hidden behind `#if DEBUG`.
- macOS may show a notification permission prompt the first run — document this in the phase log; subsequent runs use the granted permission.
- ApprovalInbox.add is an actor call from a @MainActor PaneViewModel — use Task { await ... } and don't try to await from within the synchronous parser callback.
