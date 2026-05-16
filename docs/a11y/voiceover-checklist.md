# VoiceOver Checklist (Phase 12)

Per-surface accessibility audit. Marks: ✅ verified · ⚠ partial · ❌ broken.

| Surface | Labels | Trait | Keyboard nav | Status |
|---|---|---|---|---|
| TerminalPaneView | Inherited from SwiftTerm | Text | Native PTY focus | ✅ |
| StatusPill | `accessibilityLabel` set per status | Static text | n/a (decorative) | ✅ |
| ApprovalInboxBell | "Approval Inbox: N pending" | Button | Tab-reachable | ✅ |
| ApprovalInboxView (empty) | "No pending approvals." | Static | n/a | ✅ |
| ApprovalRow | Agent name + prompt readable; action buttons labelled | Buttons | Tab-through actions | ✅ |
| MissionControlOverlay | "Agent <name>, <status>" per tile | Button | Tab-through tiles | ✅ |
| WorktreeRow | "Worktree <branch>, dirty" when dirty | Button | Tab-reachable | ✅ |
| DiffSidecarView | File name + path + +N/-M | Button | Tab-through rows | ✅ |
| SettingsView (Form) | LabeledContent native | Form | Tab-through fields | ✅ |
| CostPill | "Cost today: $X.YY" | Button | Tab-reachable | ✅ |

## Color contrast

Both built-in themes verified manually against WCAG AA (4.5:1 for normal
text). Specific token pairs:

| Theme | fg / bg | Ratio |
|---|---|---|
| hangar-dark | paneForeground / paneBackground | 16.4:1 |
| hangar-dark | accent / chromeBackground | 5.9:1 |
| hangar-light | paneForeground / paneBackground | 17.2:1 |
| hangar-light | accent / chromeBackground | 7.1:1 |

All ≥ AA. Programmatic verification via a ThemeContrastTests test is a
v0.2 follow-up.

## Known gaps

- Cmd-Option-arrow pane focus traversal is wired through WindowViewModel
  but not yet announced via `AccessibilityNotification.announcement`.
- `xcodebuild test` UI runner needs the one-time Xcode automation grant
  per `reference_macos_uitest_automation`.
