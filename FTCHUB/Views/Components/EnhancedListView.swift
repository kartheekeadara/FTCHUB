//
//  EnhancedListView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct EnhancedListView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let onDelete: ((Item) -> Void)?
    let onEdit: ((Item) -> Void)?
    @ViewBuilder let content: (Item) -> Content
    
    @State private var isRefreshing = false
    
    init(
        items: [Item],
        onDelete: ((Item) -> Void)? = nil,
        onEdit: ((Item) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(items) { item in
                    content(item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if let onEdit = onEdit {
                                Button("Edit") {
                                    onEdit(item)
                                }
                                .tint(DesignSystem.Colors.primary)
                            }
                            
                            if let onDelete = onDelete {
                                Button("Delete", role: .destructive) {
                                    onDelete(item)
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .refreshable {
            await refreshData()
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.tertiaryBackground)
                .frame(height: 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Subtitle skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.tertiaryBackground)
                .frame(height: 16)
                .frame(maxWidth: 200, alignment: .leading)
            
            // Content skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.tertiaryBackground)
                .frame(height: 14)
                .frame(maxWidth: 150, alignment: .leading)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
        )
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Gradients.primary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(message)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                }
                .primaryButtonStyle()
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Filter Chips
struct FilterChipView: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.primary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .stroke(DesignSystem.Colors.border, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        // Skeleton Loading
        SkeletonView()
        
        // Empty State
        EmptyStateView(
            icon: "tray",
            title: "No Items",
            message: "Add some items to get started",
            actionTitle: "Add Item",
            action: {}
        )
        
        // Filter Chips
        HStack {
            FilterChipView(title: "All", isSelected: true) {}
            FilterChipView(title: "Recent", isSelected: false) {}
            FilterChipView(title: "Favorites", isSelected: false) {}
        }
    }
    .padding()
}
