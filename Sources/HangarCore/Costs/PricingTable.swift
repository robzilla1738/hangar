// PricingTable — provider/model pricing (USD per 1M tokens).
// Snapshot as-of 2026-05; bake the numbers; overridable via ~/.config/hangar/pricing.json5
// when that ships in v0.2. Prices may be wrong; cost views always badge "estimated".

import Foundation

public struct ModelPricing: Sendable, Equatable {
    public let inputPerMillion: Double
    public let outputPerMillion: Double
    public let cachedInputPerMillion: Double

    public init(input: Double, output: Double, cached: Double? = nil) {
        self.inputPerMillion = input
        self.outputPerMillion = output
        self.cachedInputPerMillion = cached ?? (input * 0.1)
    }

    /// Cost in USD for a single event's token counts.
    public func cost(input: Int, output: Int, cached: Int) -> Double {
        let fromInput = (Double(input) / 1_000_000) * inputPerMillion
        let fromOutput = (Double(output) / 1_000_000) * outputPerMillion
        let fromCached = (Double(cached) / 1_000_000) * cachedInputPerMillion
        return fromInput + fromOutput + fromCached
    }
}

public enum PricingTable {
    public static let snapshotDate = "2026-05"

    public static let prices: [String: ModelPricing] = [
        // Anthropic Claude family
        "claude-opus-4-7": ModelPricing(input: 15.0, output: 75.0, cached: 1.5),
        "claude-sonnet-4-6": ModelPricing(input: 3.0, output: 15.0, cached: 0.3),
        "claude-haiku-4-5-20251001": ModelPricing(input: 1.0, output: 5.0, cached: 0.1),

        // OpenAI / Codex
        "gpt-5-codex": ModelPricing(input: 5.0, output: 15.0),
        "gpt-5": ModelPricing(input: 5.0, output: 15.0),
        "gpt-5-mini": ModelPricing(input: 0.5, output: 2.0),

        // Nous Hermes
        "hermes-3-405b": ModelPricing(input: 3.0, output: 9.0),
        "hermes-3-70b": ModelPricing(input: 1.0, output: 3.0),
    ]

    public static func pricing(for model: String) -> ModelPricing? {
        prices[model]
    }
}
