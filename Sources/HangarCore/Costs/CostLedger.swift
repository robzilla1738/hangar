// CostLedger — in-memory event store with daily/monthly totals + breakdowns.
// v0.1 persists to JSON on quit/launch; full GRDB SQLite migration lands in
// a follow-up sub-phase (the API here is stable so the swap is local).

import Foundation

public actor CostLedger {
    public private(set) var events: [CostEvent] = []

    public init() {}

    public func record(_ event: CostEvent) {
        events.append(event)
    }

    public func todayTotal(now: Date = Date()) -> Double {
        let calendar = Calendar.current
        let todayEvents = events.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
        return todayEvents.map(\.costUSD).reduce(0, +)
    }

    public func monthTotal(now: Date = Date()) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: now)
        let monthEvents = events.filter { event in
            let eventComponents = calendar.dateComponents([.year, .month], from: event.timestamp)
            return eventComponents.year == components.year
                && eventComponents.month == components.month
        }
        return monthEvents.map(\.costUSD).reduce(0, +)
    }

    public func breakdownToday(now: Date = Date()) -> CostBreakdown {
        let calendar = Calendar.current
        let todayEvents = events.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
        return breakdown(of: todayEvents)
    }

    public func breakdownMonth(now: Date = Date()) -> CostBreakdown {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: now)
        let monthEvents = events.filter {
            let eventComponents = calendar.dateComponents([.year, .month], from: $0.timestamp)
            return eventComponents.year == components.year
                && eventComponents.month == components.month
        }
        return breakdown(of: monthEvents)
    }

    private func breakdown(of events: [CostEvent]) -> CostBreakdown {
        var byProvider: [Provider: Double] = [:]
        var byAgent: [AgentProfileID: Double] = [:]
        var byModel: [String: Double] = [:]
        var estimated = 0.0
        var confirmed = 0.0
        var total = 0.0

        for event in events {
            byProvider[event.provider, default: 0] += event.costUSD
            byAgent[event.agentProfileID, default: 0] += event.costUSD
            byModel[event.model, default: 0] += event.costUSD
            total += event.costUSD
            switch event.confidence {
            case .estimated: estimated += event.costUSD
            case .confirmed: confirmed += event.costUSD
            }
        }

        return CostBreakdown(
            total: total,
            byProvider: byProvider,
            byAgent: byAgent,
            byModel: byModel,
            estimatedTotal: estimated,
            confirmedTotal: confirmed
        )
    }
}
