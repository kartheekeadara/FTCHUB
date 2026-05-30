//
//  SettingsListComponents.swift
//  FTCHUB
//
//  Shared list-row and card styling for Settings and related hubs.
//

import SwiftUI

// MARK: - Card

struct SettingsListCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.separator, lineWidth: 1)
        )
    }
}

// MARK: - Row

struct SettingsListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let statusLine: String?
    let trailing: AnyView?
    let titleColor: Color
    /// Set to false when inside a NavigationLink (avoids double-chevron).
    let showsDisclosure: Bool

    init(
        icon: String,
        title: String,
        subtitle: String,
        statusLine: String? = nil,
        trailing: AnyView? = nil,
        titleColor: Color = DesignSystem.Colors.textPrimary,
        showsDisclosure: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.statusLine = statusLine
        self.trailing = trailing
        self.titleColor = titleColor
        self.showsDisclosure = showsDisclosure
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(titleColor)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let statusLine {
                    Text(statusLine)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer(minLength: 8)

            if let trailing {
                trailing
            } else if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}

// MARK: - Divider

func settingsListDivider() -> some View {
    Divider()
        .background(DesignSystem.Colors.separator)
        .padding(.leading, 52)
}

// MARK: - Legacy alias

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let trailing: AnyView?
    let showsDisclosure: Bool

    init(
        icon: String,
        title: String,
        subtitle: String,
        trailing: AnyView? = nil,
        showsDisclosure: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.showsDisclosure = showsDisclosure
    }

    var body: some View {
        SettingsListRow(
            icon: icon,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            showsDisclosure: showsDisclosure
        )
    }
}
