SUPERGOAL_PHASE_START
Phase: 6 of 13 — Agent awareness (status pill + Approval Inbox + notifications + hotkey)
Task: Surface each pane's agent status via a Liquid Glass pill; route every awaiting-approval event into a unified Approval Inbox popover; deliver macOS notifications on new approvals; bind global hotkey Cmd-Shift-A.
Type: greenfield, ui, core
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 12
Evidence required: build/test exit codes, screenshot of pane with status pill + approval inbox popover open, test summary for approval routing
Depends on phases: 5

## Why

This is the headline differentiator. Without unified approval routing + notifications, multi-agent workflows are still a tab-juggling exercise. This phase makes Hangar's value visible.

## Work

- Add `Sources/HangarCore/Awareness/`:
  - `ApprovalInbox` actor — single source of truth for pending approvals across all panes/windows
  - `ApprovalItem` — `id`, `paneID`, `agentID`, `prompt: String`, `detectedAt`, `state: .pending | .approved | .denied | .approvedAll`
  - `ApprovalInbox.add(_:)`, `.respond(itemID:, action:)`, `.items: AsyncStream<[ApprovalItem]>`
  - `respond` writes the user's input (`y\n`, `n\n`, `a\n`) back to the originating pane's `PTYProcess.write(_:)`
- `NotificationCenter` integration via `UNUserNotificationCenter`:
  - Request authorization on first launch
  - On new approval, deliver a notification: title `Hangar — <Agent Name> needs approval`, body the prompt (truncated 80 chars), category `HANGAR_APPROVAL` with action buttons `Approve`, `Deny`, `Approve all`
  - Notification action handler routes back through `ApprovalInbox.respond`
- Global hotkey:
  - `HotKeyService` actor wrapping Carbon `RegisterEventHotKey` for system-wide capture; parses keybinding strings from `config.keybindings`
  - Cmd-Shift-A pops the Approval Inbox (focuses the menu-bar bell or opens a window-attached popover, whichever window is frontmost)
- `Sources/HangarKit/Awareness/`:
  - `StatusPill` — Liquid Glass pill rendering the agent status with icon + label (idle/working/awaiting/done/errored). Animated dot color transitions.
  - `AgentModelBadge` — small text pill: model name + provider color
  - `ApprovalInboxBell` — title-bar button with badge count; opens popover
  - `ApprovalInboxPopover` — list of `ApprovalItem` rows with action buttons; keyboard nav (j/k or arrows; enter approves)
  - Empty state for popover: "No pending approvals — your agents are all clear."
- Wire `AgentOutputParser.feed` events: when `stateChanged(.awaiting_approval(let prompt))` arrives, `ApprovalInbox.add(...)`
- Tests under `Tests/HangarCoreTests/Awareness/`:
  - `ApprovalInboxRoutingTests` — feed Claude Code fixture with an approval prompt → assert one item appears in inbox → call `respond(.approve)` → assert the originating pane received `y\n`
  - `MultiAgentInboxTests` — two simulated panes (Claude + Codex) both raise approvals; both appear; respond to each independently; assert correct routing
  - `NotificationCategoryRegistrationTests` — assert `UNUserNotificationCenter.notificationCategories` contains the `HANGAR_APPROVAL` category with three actions
  - `HotKeyServiceTests` — parse "cmd+shift+a" to the right Carbon modifier mask + key code

## Acceptance criteria (all must pass — verify each in transcript)

- `StatusPill` appears on every pane header and reflects the live `currentStatus` from Phase 5
- Approval prompt from a Claude Code fixture routes into `ApprovalInbox` within 200ms
- ApprovalInboxBell shows the right badge count and updates as items are added/responded
- Clicking "Approve" in the popover causes the originating pane to receive `y\n` (test-verified by capturing what was written)
- "Approve all" sets that item's state to `.approvedAll` and any subsequent prompts of the same type auto-route to approved
- macOS notification is delivered (visible in Notification Center) when a new approval is added; verify via `UNUserNotificationCenter.getDeliveredNotifications`
- Notification action button "Approve" routes through the same `ApprovalInbox.respond` path
- Cmd-Shift-A opens the Approval Inbox popover globally (works when another app is frontmost — focus returns to Hangar)
- All four awareness test classes pass
- Empty-state copy renders when inbox is empty
- A simulated Codex approval and Claude approval both fire correctly without cross-talk
- Build / test / lint exit 0

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of new types and views
- Test output naming the four new test classes
- `.supergoal/evidence/phase-6-approval-inbox.png` — screenshot showing a pane with status pill set to "awaiting approval" + popover open listing one approval item
- One-paragraph description of the macOS notification trigger smoke

## Notes

- Consult `macos` skill for `UNUserNotificationCenter` action category setup on macOS 26.
- Carbon `RegisterEventHotKey` is still the right API for global hotkeys on macOS 26 (no SwiftUI equivalent). Use a Carbon event handler with `kEventClassKeyboard`/`kEventHotKeyPressed`.
- Status pill animation: use SwiftUI's `withAnimation` + `phaseAnimator` (macOS 26) for the breathing dot when state is `thinking`.
- Save `reference_unusernotificationcenter_macos26_action_buttons.md` if action-button delivery has any macOS 26 idiosyncrasy.
