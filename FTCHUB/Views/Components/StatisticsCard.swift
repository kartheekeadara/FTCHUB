//
//  StatisticsCard.swift
//  FTCHUB
//
//  Phase 1: Statistics UI Component
//  Reusable card component for displaying a single statistic
//

import SwiftUI

struct StatisticsCard: View {
    let label: String
    let value: String
    let icon: String?
    let color: Color
    let showTrend: Bool
    let trendValue: Double?
    
    init(
        label: String,
        value: String,
        icon: String? = nil,
        color: Color = DesignSystem.Colors.primary,
        showTrend: Bool = false,
        trendValue: Double? = nil
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
        self.showTrend = showTrend
        self.trendValue = trendValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if showTrend, let trend = trendValue {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text(String(format: "%.1f%%", abs(trend)))
                            .font(.caption2)
                    }
                    .foregroundColor(trend >= 0 ? .green : .red)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.secondaryBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Convenience Initializers

extension StatisticsCard {
    /// Creates a card for OPR display
    static func opr(_ value: Double?) -> StatisticsCard {
        StatisticsCard(
            label: "OPR",
            value: value != nil ? String(format: "%.2f", value!) : "N/A",
            icon: "chart.line.uptrend.xyaxis",
            color: .blue
        )
    }
    
    /// Creates a card for DPR display
    static func dpr(_ value: Double?) -> StatisticsCard {
        StatisticsCard(
            label: "DPR",
            value: value != nil ? String(format: "%.2f", value!) : "N/A",
            icon: "shield.fill",
            color: .orange
        )
    }
    
    /// Creates a card for CCWM display
    static func ccwm(_ value: Double?) -> StatisticsCard {
        StatisticsCard(
            label: "CCWM",
            value: value != nil ? String(format: "%.2f", value!) : "N/A",
            icon: "arrow.up.arrow.down",
            color: .green
        )
    }
    
    /// Creates a card for win rate display
    static func winRate(_ value: Double?) -> StatisticsCard {
        StatisticsCard(
            label: "Win Rate",
            value: value != nil ? String(format: "%.1f%%", value! * 100) : "N/A",
            icon: "trophy.fill",
            color: .yellow
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        StatisticsCard.opr(142.5)
        StatisticsCard.dpr(98.3)
        StatisticsCard.ccwm(44.2)
        StatisticsCard.winRate(0.75)
    }
    .padding()
}
