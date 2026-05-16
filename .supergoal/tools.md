# Detected tools (this session)

## Universal tooling
- Bash, Read, Write, Edit, TaskCreate/Update/List, Skill, Agent (subagents), AskUserQuestion, ScheduleWakeup
- ToolSearch (deferred tools available on demand)

## Web + docs
- **Context7** (`mcp__claude_ai_Context7__resolve-library-id`, `mcp__claude_ai_Context7__query-docs`) — available. Use for current docs on SwiftTerm, Sparkle 2, GRDB.swift, swift-nio, libghostty, MCP Swift SDK.
- **WebSearch / WebFetch** — available. Use for community patterns (notarization, Liquid Glass APIs, agent CLI behaviors).

## Agents (subagent_type)
- `Explore` — read-only fast search
- `Plan` — implementation strategy
- `general-purpose` — multi-step research
- `geo-*`, `svvarm:*` — domain agents, not applicable here

## Project skills to consult during phases
| Skill | When |
|---|---|
| `macos` | Every Swift/SwiftUI phase — patterns, AppKit bridging, macOS 26 Tahoe APIs, Liquid Glass |
| `swift` | Swift 6 strict concurrency, performance, language idioms |
| `design` | Liquid Glass surfaces, animations, Apple HIG fit |
| `security` | Permission handling, signing, sandboxing decisions, secure storage of API keys |
| `testing` | XCTest infra, characterization tests, snapshot tests for UI |
| `product` | Spec docs, architecture notes |
| `release-review` | Final pre-tag review before notarization & release |
| `generators` | Skim for any reusable patterns (logging, settings, persistence) |
| `app-store` | Not directly applicable (not shipping App Store) — skip |
| `legal` | LICENSE (MIT) + minimal NOTICE file |

## Notes
- Pinecone MCP available but not relevant for v0.1 (semantic history is v0.2+).
- No live GitHub MCP — use `gh` CLI via Bash for repo/release ops.
- No live Xcode MCP — drive Xcode/xcodebuild via Bash; auth grants surface to user.
