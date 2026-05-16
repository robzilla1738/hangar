// CostLedgerTests — record, totals, breakdown across providers/agents/models.

import Foundation
import XCTest

@testable import HangarCore

final class CostLedgerTests: XCTestCase {
    private func makeEvent(
        agent: String = "claude_code",
        provider: Provider = .anthropic,
        model: String = "claude-opus-4-7",
        cost: Double,
        timestamp: Date = Date(),
        confidence: CostEvent.Confidence = .estimated
    ) -> CostEvent {
        CostEvent(
            timestamp: timestamp,
            agentProfileID: agent,
            provider: provider,
            model: model,
            inputTokens: 0,
            outputTokens: 0,
            costUSD: cost,
            confidence: confidence
        )
    }

    func testRecordedEventIncreasesTotal() async {
        let ledger = CostLedger()
        await ledger.record(makeEvent(cost: 1.25))
        let total = await ledger.todayTotal()
        XCTAssertEqual(total, 1.25, accuracy: 0.0001)
    }

    func testTotalsAcrossMultipleEvents() async {
        let ledger = CostLedger()
        await ledger.record(makeEvent(cost: 1.0))
        await ledger.record(makeEvent(cost: 2.5))
        await ledger.record(makeEvent(cost: 0.5))
        let total = await ledger.todayTotal()
        XCTAssertEqual(total, 4.0, accuracy: 0.0001)
    }

    func testYesterdayDoesNotCountTowardToday() async {
        let ledger = CostLedger()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        await ledger.record(makeEvent(cost: 99.0, timestamp: yesterday))
        await ledger.record(makeEvent(cost: 1.0))
        let total = await ledger.todayTotal()
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
    }

    func testBreakdownByProviderAndAgent() async {
        let ledger = CostLedger()
        await ledger.record(makeEvent(agent: "claude_code", provider: .anthropic, cost: 3.0))
        await ledger.record(makeEvent(agent: "codex", provider: .openai, cost: 2.0))
        await ledger.record(makeEvent(agent: "hermes", provider: .nous, cost: 1.0))
        let breakdown = await ledger.breakdownToday()
        XCTAssertEqual(breakdown.total, 6.0, accuracy: 0.0001)
        XCTAssertEqual(breakdown.byProvider[.anthropic], 3.0)
        XCTAssertEqual(breakdown.byProvider[.openai], 2.0)
        XCTAssertEqual(breakdown.byProvider[.nous], 1.0)
        XCTAssertEqual(breakdown.byAgent["claude_code"], 3.0)
    }

    func testConfidenceSplit() async {
        let ledger = CostLedger()
        await ledger.record(makeEvent(cost: 1.0, confidence: .estimated))
        await ledger.record(makeEvent(cost: 2.0, confidence: .confirmed))
        let breakdown = await ledger.breakdownToday()
        XCTAssertEqual(breakdown.estimatedTotal, 1.0, accuracy: 0.0001)
        XCTAssertEqual(breakdown.confirmedTotal, 2.0, accuracy: 0.0001)
    }
}
