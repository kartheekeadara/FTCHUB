//
//  EnhancedEmptyStateView.swift
//  FTCHUB
//
//  Created for Phase 6: Error Handling & User Feedback Improvements
//

import SwiftUI

/// Enhanced empty state view with helpful actions and clear messaging
struct EnhancedEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    let secondaryActionTitle: String?
    let secondaryAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            // Icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.primary.opacity(0.1),
                                DesignSystem.Colors.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(DesignSystem.Gradients.primary)
            }
            
            // Title
            Text(title)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Actions
            if let actionTitle = actionTitle, let action = action {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.subheadline)
                            Text(actionTitle)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Gradients.primary)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    if let secondaryActionTitle = secondaryActionTitle, let secondaryAction = secondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryActionTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.md)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

/// Predefined empty states for common scenarios
extension EnhancedEmptyStateView {
    static func noItems(
        itemName: String,
        actionTitle: String = "Add Item",
        action: @escaping () -> Void
    ) -> EnhancedEmptyStateView {
        EnhancedEmptyStateView(
            icon: "tray",
            title: "No \(itemName) Yet",
            message: "Get started by adding your first \(itemName.lowercased()).",
            actionTitle: actionTitle,
            action: action
        )
    }
    
    static func noResults(
        searchTerm: String? = nil,
        clearAction: (() -> Void)? = nil
    ) -> EnhancedEmptyStateView {
        EnhancedEmptyStateView(
            icon: "magnifyingglass",
            title: searchTerm != nil ? "No Results Found" : "Nothing Here",
            message: searchTerm != nil ?
                "We couldn't find anything matching \"\(searchTerm!)\". Try different search terms." :
                "No items match your current filters.",
            actionTitle: clearAction != nil ? "Clear Filters" : nil,
            action: clearAction
        )
    }
    
    static func noTeam(
        action: @escaping () -> Void
    ) -> EnhancedEmptyStateView {
        EnhancedEmptyStateView(
            icon: "person.3",
            title: "No Team Yet",
            message: "Join or create a team to get started with team management features.",
            actionTitle: "Get Started",
            action: action
        )
    }
    
    static func noMatches(
        action: @escaping () -> Void
    ) -> EnhancedEmptyStateView {
        EnhancedEmptyStateView(
            icon: "calendar",
            title: "No Matches Scheduled",
            message: "Add matches to your schedule to track upcoming competitions.",
            actionTitle: "Add Match",
            action: action
        )
    }
    
    static func noReports(
        action: @escaping () -> Void
    ) -> EnhancedEmptyStateView {
        EnhancedEmptyStateView(
            icon: "chart.bar.doc.horizontal",
            title: "No Scouting Reports",
            message: "Start scouting matches to capture robot capabilities and match trends.",
            actionTitle: "Create Report",
            action: action
        )
    }
}




