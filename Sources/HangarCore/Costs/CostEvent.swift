// CostEvent — one row in the SQLite cost ledger.
// GRDB schema migration lands alongside CostLedger.

import Foundation

public struct CostEvent: Identifiable, Codable, Sendable, Equatable {
    public enum Confidence: String, Codable, Sendable {
        case estimated  // parsed from CLI output
        case confirmed  // backfilled from provider API
    }

    public let id: UUID
    public let timestamp: Date
    public let paneID: UUID?
    public let agentProfileID: AgentProfileID
    public let provider: Provider
    public let model: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let cachedInputTokens: Int
    public let costUSD: Double
    public let confidence: Confidence

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        paneID: UUID? = nil,
        agentProfileID: AgentProfileID,
        provider: Provider,
        model: String,
        inputTokens: Int,
        outputTokens: Int,
        cachedInputTokens: Int = 0,
        costUSD: Double,
        confidence: Confidence = .estimated
    ) {
        self.id = id
        self.timestamp = timestamp
        self.paneID = paneID
        self.agentProfileID = agentProfileID
        self.provider = provider
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cachedInputTokens = cachedInputTokens
        self.costUSD = costUSD
        self.confidence = confidence
    }
}

public struct CostBreakdown: Sendable, Equatable {
    public var total: Double
    public var byProvider: [Provider: Double]
    public var byAgent: [AgentProfileID: Double]
    public var byModel: [String: Double]
    public var estimatedTotal: Double
    public var confirmedTotal: Double

    public init(
        total: Double = 0,
        byProvider: [Provider: Double] = [:],
        byAgent: [AgentProfileID: Double] = [:],
        byModel: [String: Double] = [:],
        estimatedTotal: Double = 0,
        confirmedTotal: Double = 0
    ) {
        self.total = total
        self.byProvider = byProvider
        self.byAgent = byAgent
        self.byModel = byModel
        self.estimatedTotal = estimatedTotal
        self.confirmedTotal = confirmedTotal
    }
}
