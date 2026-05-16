# Hangar Security Review (Phase 12)

Snapshot of the v0.1 security posture. Updates each release; flagged
items become issues with `security` label.

## Threat model

Hangar runs as a **trusted local app** with hardened runtime + Developer
ID signing. It is **not sandboxed** (terminals spawn arbitrary child
processes; sandboxing is impractical). The threat surface:

| Surface | Mitigation |
|---|---|
| Local privilege escalation via PTY / hotkey | No setuid binaries; PTY is per-pane and owned by the user |
| Malicious `config.json5` | JSON5 parse failures retain previous snapshot; no eval or arbitrary command execution at config-load time |
| Compromise of stored Keychain API keys | macOS Keychain ACLs (`SecItem*` family), service name `dev.robcourson.hangar`, account-per-provider |
| Supply-chain attacks on SwiftTerm / GRDB / Sparkle | SPM `Package.resolved` pinned; major bumps reviewed manually |
| Agent CLIs doing arbitrary things in their PTY | Out of scope — Hangar surfaces the approval prompts but does not sandbox the agent itself |

## Entitlements (Hangar/Hangar.entitlements)

```xml
com.apple.security.cs.allow-jit                       = true
com.apple.security.cs.disable-library-validation     = true
com.apple.security.cs.allow-unsigned-executable-memory = true
com.apple.security.cs.allow-dyld-environment-variables = true
com.apple.security.cs.disable-executable-page-protection = false
com.apple.security.automation.apple-events           = true
com.apple.security.device.audio-input                = true
```

JIT + unsigned executable memory + dyld env vars are required by
terminal-style apps (vim, node, deno, python all need them). Page
protection stays enforced.

## Diff sweep

Repository searched for stored secrets at every phase. Patterns checked:
`sk-…`, `claude-api`, `OPENAI_API_KEY=`, hex strings ≥ 40 chars, JWT
prefixes (`eyJ`).

Result this phase: **0 hits**.

## Input validation

- `config.json5` parsed via `JSONSerialization.json5Allowed`; on failure
  the previous snapshot is retained; no crash path.
- Worktree branch names sanitized via `GitService.sanitizedDirectoryName`
  before reaching the filesystem (allows alphanumerics, hyphen,
  underscore; everything else → `-`).
- FSEvents paths normalized — ignore patterns skip `.git`, `node_modules`,
  `DerivedData`, `.build`, `.swiftpm` and the watcher does not traverse
  packaged directories (`skipsPackageDescendants`).

## Hardened runtime check

```bash
xcodebuild -showBuildSettings -scheme Hangar | grep ENABLE_HARDENED_RUNTIME
# → ENABLE_HARDENED_RUNTIME = YES
```

## Findings

None this phase. Items previously flagged:

| ID | Phase | Status | Notes |
|---|---|---|---|
| (none) | — | — | — |

## Out of scope for v0.1

- A built-in agent-level sandbox (no current macOS mechanism we control)
- Encrypted cost ledger at rest (SQLite WAL is local; not in v0.1 threat model)
- Anti-tamper of the .app bundle beyond Developer ID + notarization
