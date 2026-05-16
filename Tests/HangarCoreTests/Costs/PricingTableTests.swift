// PricingTableTests — sanity check pricing entries + cost arithmetic.

import XCTest

@testable import HangarCore

final class PricingTableTests: XCTestCase {
    func testAllRequiredModelsPresent() {
        let required = [
            "claude-opus-4-7",
            "claude-sonnet-4-6",
            "claude-haiku-4-5-20251001",
            "gpt-5-codex",
            "gpt-5",
            "hermes-3-405b",
        ]
        for model in required {
            XCTAssertNotNil(PricingTable.pricing(for: model), "Missing pricing for \(model)")
        }
    }

    func testCostFormulaScalesByTokenCount() {
        let pricing = ModelPricing(input: 10.0, output: 30.0, cached: 1.0)
        let cost = pricing.cost(input: 1_000_000, output: 500_000, cached: 0)
        // 1M input × $10 + 0.5M output × $30 = $10 + $15 = $25
        XCTAssertEqual(cost, 25.0, accuracy: 0.0001)
    }

    func testCachedInputReducesCost() {
        let pricing = ModelPricing(input: 10.0, output: 30.0, cached: 1.0)
        let regular = pricing.cost(input: 1_000_000, output: 0, cached: 0)
        let cached = pricing.cost(input: 0, output: 0, cached: 1_000_000)
        XCTAssertGreaterThan(regular, cached)
    }
}
