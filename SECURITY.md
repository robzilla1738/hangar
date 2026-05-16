# Security Policy

## Supported Versions

Only the latest minor release of Hangar receives security fixes.

| Version | Supported |
|---|---|
| 0.1.x | ✅ |
| < 0.1 | ❌ |

## Reporting a Vulnerability

Please report security vulnerabilities **privately** via email to `robertcourson96@gmail.com`. Include:

- A description of the vulnerability
- Steps to reproduce
- The version of Hangar affected
- Your name and affiliation (optional — for credit)

You should receive an acknowledgement within 72 hours and a status update within 7 days.

Do **not** open public GitHub issues for security bugs.

## Scope

Hangar runs as a **trusted local app** on macOS with hardened runtime and Developer ID signing. It is not sandboxed (terminals spawn arbitrary child processes; sandboxing is impractical). The threat model focuses on:

- Local privilege escalation via Hangar's PTY or hotkey services
- Malicious config injection via `~/.config/hangar/config.json5`
- Compromise of stored Keychain API keys
- Supply-chain attacks via SwiftTerm / GRDB / Sparkle dependencies

We do **not** treat the following as security issues:

- Remote agents (Claude Code, Codex, Hermes) doing arbitrary things in their own PTY — Hangar's job is to surface those approvals to the user, not to sandbox the agents themselves.
