// CostPill — title-bar component showing today's spend.

import SwiftUI

public struct CostPill: View {
    private let todayUSD: Double
    private let warnAtUSD: Double
    private let hardStopAtUSD: Double?
    private let onTap: () -> Void

    public init(
        todayUSD: Double,
        warnAtUSD: Double,
        hardStopAtUSD: Double? = nil,
        onTap: @escaping () -> Void
    ) {
        self.todayUSD = todayUSD
        self.warnAtUSD = warnAtUSD
        self.hardStopAtUSD = hardStopAtUSD
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 11))
                Text(formatted)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cost today: \(formatted)")
    }

    private var formatted: String {
        String(format: "$%.2f", todayUSD)
    }

    private var tint: Color {
        if let hardStop = hardStopAtUSD, todayUSD >= hardStop { return .red }
        if todayUSD >= warnAtUSD { return .orange }
        if todayUSD >= warnAtUSD / 2 { return .yellow }
        return .secondary
    }
}
