SUPERGOAL_PHASE_START
Phase: 8 of 13 — Cost ledger + cost pill
Task: Implement the SQLite-backed cost ledger with per-profile token parsers, a title-bar cost pill showing today's spend, a click-to-open breakdown sheet, optional alert/hard-stop thresholds, and a stub nightly reconciliation hook against provider APIs.
Type: greenfield, core, ui
Mandatory commands: xcodebuild -scheme Hangar -destination 'platform=macOS' build, xcodebuild -scheme Hangar -destination 'platform=macOS' test, swiftlint --strict, swift-format lint --recursive --strict Sources Tests Hangar
Acceptance criteria: 12
Evidence required: build/test exit codes, screenshot of cost pill + breakdown sheet, parser unit-test summary
Depends on phases: 5

## Why

If cost is invisible, agents become a roulette wheel. A live cost pill creates the feedback loop that makes multi-agent use sustainable. This is the second-most-cited reason developers don't run agents in parallel today.

## Work

- Add `Sources/HangarCore/Costs/`:
  - `CostEvent` — `id`, `timestamp`, `paneID`, `agentProfileID`, `provider`, `model`, `inputTokens: Int`, `outputTokens: Int`, `cachedInputTokens: Int`, `costUSD: Double`, `confidence: .estimated | .confirmed`, `sourceMessage: String?` (debug aid)
  - GRDB table `cost_events`; migration appended
  - `CostLedger` actor with: `record(_ event: CostEvent)`, `todayTotal() -> Double`, `monthTotal() -> Double`, `breakdownToday() -> CostBreakdown`, `byAgent(in: Range<Date>) -> [AgentProfileID: Double]`, `byProject(in:) -> [Project.ID: Double]`, `events: AsyncStream<CostEvent>`
  - `CostBreakdown` — `total`, `byProvider`, `byAgent`, `byProject`, `byModel`, `confidenceSplit`
  - `PricingTable` — static table of input/output prices per model for Anthropic / OpenAI / Nous (defaults shipped in code; overridable via `~/.config/hangar/pricing.json5`); reference pricing as-of 2026-05; surface clearly in a doc comment that pricing can be wrong and breakdowns are estimates
- Per-profile cost parsers (Phase 5 left these stubbed):
  - `ClaudeCodeCostParser` — parse Claude Code's "Used N input tokens, M output tokens" / `[N tokens]` / `cache_creation_input_tokens` style hints
  - `CodexCostParser` — parse Codex's "Used N input + M output" / "Total tokens: X" style
  - `HermesCostParser` — Hermes has limited cost output; fall back to length-based heuristic when no explicit count is emitted (mark `.estimated` with low confidence flag)
- Background reconciliation (stub for v0.1; full impl in v0.2):
  - `CostReconciler` actor scheduled by `BackgroundJobsService`; reads Keychain (Phase 12 will provide the keys) for provider API keys; if present, queries the Anthropic / OpenAI usage endpoints and upserts `.confirmed` events
  - For v0.1, the reconciler only runs when explicitly invoked from a debug menu (Hangar > Debug > Reconcile Costs Now); fully autoscheduling lands in v0.2
- `Sources/HangarKit/Costs/`:
  - `CostPill` — title-bar component; shows today's total formatted (`$4.27`); color escalates: gray default, yellow if `>= warn_at_usd / 2`, red if `>= warn_at_usd`; pulsing if hard_stop reached
  - `CostBreakdownSheet` — sheet presented on pill click; charts (use Swift Charts) for: today by provider, today by agent, today by project; toggle Today / This Month
  - `CostAlertBanner` — when daily spend crosses `costs.warn_at_usd`, a non-blocking banner appears in the title-bar area: "You've spent $X today. Configured warn-at is $Y." Dismissible per day
  - When `costs.hard_stop_at_usd` is set and exceeded, new agent spawns show a confirmation sheet before launching ("Daily hard-stop reached — really start another agent?")
- Tests under `Tests/HangarCoreTests/Costs/`:
  - `CostParserClaudeCodeTests`, `CostParserCodexTests`, `CostParserHermesTests` — feed recorded fixture chunks (reuse Phase 5 fixtures + new cost-flavored ones); assert parsed `CostEvent`s match expected token counts + computed USD
  - `CostLedgerAggregationTests` — insert N events; assert daily/monthly/byAgent/byProject totals
  - `PricingTableTests` — assert all three providers have at least one model row; assert `costFor(...) > 0` for known inputs
  - `CostAlertThresholdTests` — simulate event stream that crosses warn + hard-stop; assert banner shown / confirm-sheet routed
  - `CostReconcilerStubTests` — invoking the reconciler without an API key in Keychain succeeds gracefully (no-op, logs reason)

## Acceptance criteria (all must pass — verify each in transcript)

- `CostEvent` and GRDB `cost_events` table exist; migration applies on launch
- The three cost parsers parse their fixtures into expected `CostEvent`s (per-class test asserts)
- Running a real `claude` command in a pane creates at least one `CostEvent` and updates the pill in real time
- Cost pill shows today's total, formatted `$X.YY`
- Click pill opens the breakdown sheet with three charts populated
- Warn-at threshold trigger displays the banner and writes a notable event to `STATE.md`
- Hard-stop threshold triggers a confirmation sheet before new agent spawn
- All five cost test classes pass
- Pricing table has entries for at least `claude-opus-4-7`, `claude-sonnet-4-6`, `gpt-5-codex`, `gpt-5`, `hermes-3-405b`
- Estimated vs confirmed status visible in the breakdown sheet (badge on each row)
- Manually invoking Debug > Reconcile Costs Now logs "no API key in Keychain — skipping" if no key is configured
- Build / test / lint exit 0

## Mandatory commands (run each, surface last ~10 lines + exit code)

- `xcodebuild -scheme Hangar -destination 'platform=macOS' build | xcbeautify`
- `xcodebuild -scheme Hangar -destination 'platform=macOS' test | xcbeautify`
- `swiftlint --strict`
- `swift-format lint --recursive --strict Sources Tests Hangar`

## Evidence required in transcript

- File listing of `Sources/HangarCore/Costs/` and `Sources/HangarKit/Costs/`
- Test output naming all five cost test classes with pass/fail breakdown
- `.supergoal/evidence/phase-8-cost-pill.png` — screenshot showing the cost pill and (in a second image or composite) the open breakdown sheet
- One paragraph describing the live-pane smoke (run claude with a small prompt, watch the pill increment)

## Notes

- Consult Context7 for current Anthropic + OpenAI usage-endpoint shapes (they change periodically). The reconciler is stubbed for v0.1 but the API shape should be documented in `docs/cost-reconciliation.md`.
- Swift Charts is built-in (no dep); use `BarMark` for the breakdown.
- Save `reference_pricing_table_2026_q2.md` with the actual table contents as a snapshot in time, so future runs know which prices were active.
