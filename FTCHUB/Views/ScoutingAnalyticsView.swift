//
//  ScoutingAnalyticsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ScoutingAnalyticsView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(DesignSystem.Gradients.primary)
                    
                    Text("Scouting Analytics")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Analyze team performance and trends")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.xl)
                
                // Analytics Cards
                VStack(spacing: DesignSystem.Spacing.md) {
                    AnalyticsCard(
                title: "Total Reports",
                value: "\(scoutingService.scoutingReports.count)",
                icon: "doc.text.fill",
                color: DesignSystem.Colors.primary
            )
            
                    AnalyticsCard(
                title: "Templates",
                value: "\(scoutingService.scoutingTemplates.count)",
                icon: "list.bullet.rectangle.fill",
                        color: DesignSystem.Colors.accent
                    )
                    
                    AnalyticsCard(
                        title: "Teams Scouted",
                        value: "0",
                        icon: "person.3.fill",
                        color: DesignSystem.Colors.secondary
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Placeholder for future analytics
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("More analytics coming soon!")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .background(DesignSystem.Colors.background)
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.title3)
                .fontWeight(.semibold)
                        .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: DesignSystem.Colors.shadow, radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
        ScoutingAnalyticsView()
            .environmentObject(ScoutingService())
}