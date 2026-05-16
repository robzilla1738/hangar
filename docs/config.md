# Hangar configuration

Hangar reads `~/.config/hangar/config.json5` on launch and watches it for changes (hot reload). The full schema and defaults are documented below. Phase 3 lands the parser; this file ships ahead of it so the schema is locked.

```json5
{
  // General behavior on launch
  general: {
    startup: "new_window", // "new_window" | "restore_last"
  },

  // Visual appearance
  appearance: {
    theme: "hangar-dark", // "hangar-dark" | "hangar-light" | path to custom theme
    transparency: 0.05,   // 0.0–1.0
    titlebar_style: "unified", // "unified" | "inset"
  },

  // Fonts
  fonts: {
    family: "SF Mono",
    size: 13,
    line_height: 1.2,
  },

  // Agent profile detection
  agents: {
    claude_code: { binary: "claude" },
    codex:       { binary: "codex" },
    hermes:      { binary: "hermes" },
    // Additional custom detectors:
    extra: [
      // { name: "my-agent", binary: "myagent", profile: "raw_shell" },
    ],
  },

  // Keybindings (all rebindable)
  keybindings: {
    mission_control: "cmd+0",
    approval_inbox:  "cmd+shift+a",
    new_worktree:    "cmd+shift+w",
  },

  // Cost guardrails
  costs: {
    warn_at_usd: 20.0,
    hard_stop_at_usd: null, // null disables
  },

  // Worktree management
  worktree: {
    base_dir: "~/Hangar/Worktrees",
  },

  // Experimental flags
  experimental: {
    use_libghostty: false, // swap SwiftTerm for libghostty (v0.2+)
  },
}
```

Comments and trailing commas are permitted (JSON5). Hangar revalidates on every file write; parse errors leave the previous snapshot in place and surface a non-blocking banner.
