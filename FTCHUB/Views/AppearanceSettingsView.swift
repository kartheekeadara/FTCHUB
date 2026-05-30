//
//  AppearanceSettingsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("ftchub.colorScheme") private var colorSchemePreference: String = "light"
    @Environment(\.colorScheme) private var systemColorScheme

    private struct ThemeOption: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let previewScheme: ColorScheme
    }

    private var themeOptions: [ThemeOption] {
        [
            ThemeOption(
                id: "light",
                title: "Light",
                subtitle: "Bright backgrounds and dark text",
                previewScheme: .light
            ),
            ThemeOption(
                id: "dark",
                title: "Dark",
                subtitle: "Dark backgrounds, easier on the eyes",
                previewScheme: .dark
            ),
            ThemeOption(
                id: "system",
                title: "System",
                subtitle: "Matches your iPhone appearance",
                previewScheme: systemColorScheme
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                headerSection

                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(themeOptions) { option in
                        AppearanceThemeOptionCard(
                            title: option.title,
                            subtitle: option.subtitle,
                            previewScheme: option.previewScheme,
                            isSystemOption: option.id == "system",
                            isSelected: colorSchemePreference == option.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                colorSchemePreference = option.id
                            }
                            DesignSystem.Haptics.impact(.light)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .background(Color(.systemBackground))
        .navigationTitle(L10n.Settings.appearanceTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Theme")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text("Choose how FTC HUB looks on this device. Changes apply immediately.")
                .font(.system(size: 15))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Theme Option Card

private struct AppearanceThemeOptionCard: View {
    let title: String
    let subtitle: String
    let previewScheme: ColorScheme
    let isSystemOption: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                AppearanceThemePreview(
                    scheme: previewScheme,
                    showsSystemBadge: isSystemOption
                )
                .frame(maxWidth: .infinity)
                .frame(height: 128)

                HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(
                            isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary
                        )
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Mini App Preview

private struct AppearanceThemePreview: View {
    let scheme: ColorScheme
    var showsSystemBadge: Bool = false

    private var palette: AppearancePreviewPalette {
        AppearancePreviewPalette(scheme: scheme)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 14)
                .fill(palette.screenBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(palette.border, lineWidth: 1)
                )

            VStack(spacing: 0) {
                // Mock status / nav
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(palette.primary)
                        .frame(width: 28, height: 6)
                    Spacer()
                    Circle()
                        .fill(palette.secondaryText)
                        .frame(width: 6, height: 6)
                    Circle()
                        .fill(palette.secondaryText)
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Mock content card
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(palette.primary)
                        .frame(width: 56, height: 8)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(palette.primaryText)
                        .frame(height: 6)
                        .frame(maxWidth: .infinity)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(palette.secondaryText)
                        .frame(width: 80, height: 5)

                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(palette.cardBackground)
                            .frame(height: 22)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(palette.cardBackground)
                            .frame(height: 22)
                    }
                    .padding(.top, 4)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            if showsSystemBadge {
                Label("Auto", systemImage: "iphone")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(palette.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(palette.cardBackground.opacity(0.95))
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
    }
}

private struct AppearancePreviewPalette {
    let screenBackground: Color
    let cardBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let primary: Color
    let border: Color

    init(scheme: ColorScheme) {
        switch scheme {
        case .dark:
            screenBackground = Color(red: 0.04, green: 0.04, blue: 0.04)
            cardBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
            primaryText = .white
            secondaryText = Color(red: 0.56, green: 0.56, blue: 0.58)
            primary = Color(red: 0.91, green: 0.64, blue: 0.35)
            border = Color(red: 0.25, green: 0.25, blue: 0.27)
        default:
            screenBackground = Color(red: 0.99, green: 0.988, blue: 0.986)
            cardBackground = .white
            primaryText = Color(red: 0.05, green: 0.05, blue: 0.05)
            secondaryText = Color(red: 0.45, green: 0.45, blue: 0.45)
            primary = Color(red: 0.91, green: 0.64, blue: 0.35)
            border = Color(red: 0.88, green: 0.88, blue: 0.89)
        }
    }
}

// MARK: - Legacy (guest inline picker still uses compact previews if needed)

struct ColorSchemePreview: View {
    let title: String
    let isSelected: Bool
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            AppearanceThemePreview(scheme: colorScheme)
                .frame(height: 60)

            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
