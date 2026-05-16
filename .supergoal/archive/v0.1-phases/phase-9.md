SUPERGOAL_PHASE_START
Phase: 9 of 13 — Worktree shelf
Task: Build a left-sidebar worktree shelf that lists every git worktree for the current project; supports Cmd-Shift-W to create a new worktree, click-to-jump (focus a pane in that cwd), and surface dirty/clean state per worktree.
Type: greenfield, ui, core
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 10
Evidence required: build/test exit codes, screenshot of shelf with 2+ worktrees, jump-to-worktree round-trip
Depends on phases: 4

## Why

Multi-agent + multi-branch is the real-world use case: one Claude on `main`, one Codex on a feature branch, both in worktrees so they don't clobber each other. Today, doing this is a manual cd/branch/worktree dance. Hangar makes it one keystroke.

## Work

- Add `Sources/HangarCore/Git/`:
  - `GitService` actor: shells out to `git` via `Process`; methods: `worktrees(in repoRoot: URL) -> [Worktree]`, `createWorktree(at path: URL, branch: String, baseRef: String) -> Worktree`, `removeWorktree(at: URL)`, `status(of: URL) -> WorktreeStatus`
  - `Worktree` — `path: URL`, `branch: String`, `headSHA: String`, `isDirty: Bool`, `aheadCount: Int`, `behindCount: Int`
  - `WorktreeStatus` — `clean | dirty(stagedCount: Int, unstagedCount: Int, untrackedCount: Int)`
- Worktrees live under `worktree.base_dir` from config (default `~/Hangar/Worktrees`); when creating, Hangar names the directory `<repoName>-<branch>` (sanitized)
- Add `Sources/HangarKit/Sidebar/`:
  - `LeftSidebar` — collapsible sidebar with three sections: Projects (from Phase 4), Context shelf placeholder (v0.2), Worktrees
  - `WorktreeShelfSection` — list rows; each row shows branch name, repo name, dirty dot, ahead/behind chevrons; right-click context menu for Remove (with confirmation)
  - `NewWorktreeSheet` — sheet shown on Cmd-Shift-W; prompts for branch name (with autocomplete from `git branch --all`); option to create-from-current-branch or pick-base; "Open in new tab" toggle
  - Keyboard: Cmd-Shift-W triggers the sheet; Enter creates; Escape cancels
- Behavior on click:
  - If the user has a pane in focus, change its cwd by sending `cd <path>\n` (raw shell only) — for agent panes, prompt first ("This pane is running claude. Open the worktree in a new pane instead?")
  - If no pane is focused or "Open in new tab" is on, create a new tab with a fresh pane in the worktree cwd
- Tests under `Tests/HangarCoreTests/Git/`:
  - `GitServiceWorktreeRoundTripTests` — in a temp directory, init a repo, create a worktree via service, list it, remove it; assert success at each step (skip on CI if git not installed — but git is standard on macos-26 runners)
  - `GitServiceStatusParsingTests` — given canned `git status --porcelain=v2` output, parse correctly into `WorktreeStatus`
  - `GitServiceWorktreeNamingTests` — sanitize branch names with slashes / special chars into safe directory names

## Acceptance criteria (all must pass — verify each in transcript)

- Sidebar opens via View > Toggle Sidebar; closes again on same shortcut
- Worktree section lists all worktrees for the current project (verified against `git worktree list` output)
- Each row shows branch, dirty dot, ahead/behind chevrons
- Cmd-Shift-W opens the new-worktree sheet
- Creating a worktree adds a directory under `~/Hangar/Worktrees/<repo>-<branch>` (or configured base) and the sheet dismisses successfully
- Clicking a worktree with an agent pane focused prompts; clicking with a shell pane focused changes the pane's cwd
- Removing a worktree from the right-click menu calls `git worktree remove` and the row disappears
- All three Git test classes pass
- Build / test / lint exit 0
- Worktree base dir honors `config.worktree.base_dir` (test with a non-default value)

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of `Sources/HangarCore/Git/` and `Sources/HangarKit/Sidebar/`
- Test output naming the three Git test classes
- `.supergoal/evidence/phase-9-worktree-shelf.png` — screenshot showing sidebar with 2+ worktrees, one dirty
- One-paragraph description of the create→jump→remove round-trip

## Notes

- Shelling out to `git` keeps v0.1 dep-light. v0.2 may swap to libgit2/SwiftGit2 for richer status without subprocess overhead.
- Use `--porcelain=v2` for stable parsing.
- Worktrees can't be created for a branch that's already checked out elsewhere — surface this error path with a clear sheet ("Branch already checked out in <path>").
- Save `reference_git_worktree_porcelain_v2.md` if any non-obvious parsing tail-case shows up.
