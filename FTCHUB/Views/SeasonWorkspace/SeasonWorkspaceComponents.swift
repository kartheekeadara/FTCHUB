//
//  SeasonWorkspaceComponents.swift
//  FTCHUB
//
//  Shared layout components for Season workspace pages.
//

import SwiftUI

// MARK: - Section card

struct SeasonHubSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)
            
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Link row

struct SeasonHubLinkRow: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    let tint: Color
    var trailingSystemImage: String = "chevron.right"
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundColor(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: trailingSystemImage)
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm + 2)
        .contentShape(Rectangle())
    }
}

// MARK: - Row divider

struct SeasonHubRowDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 62)
    }
}

// MARK: - Hub row (for top-level category navigation)

struct SeasonWorkspaceHubRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.04), radius: 6, x: 0, y: 2)
        .contentShape(Rectangle())
    }
}
