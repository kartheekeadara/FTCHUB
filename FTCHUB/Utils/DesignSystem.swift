//
//  DesignSystem.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct DesignSystem {
    // MARK: - Colors (Warm Earthy Tones - Refined)
    struct Colors {
        // Primary warm brown/orange inspired by UI inspiration - More saturated
        static let primary = Color(red: 0.75, green: 0.45, blue: 0.25) // Rich warm brown
        static let secondary = Color(red: 0.35, green: 0.35, blue: 0.35) // Medium gray
        static let accent = Color(red: 0.95, green: 0.65, blue: 0.35)  // Golden accent
        static let success = Color(red: 0.2, green: 0.7, blue: 0.4)
        static let warning = Color(red: 0.95, green: 0.65, blue: 0.15)
        static let error = Color(red: 0.9, green: 0.25, blue: 0.25)
        
        // Background colors - clean white and light gray with subtle warmth
        static let background = Color(red: 0.99, green: 0.988, blue: 0.986) // Warm white
        static let secondaryBackground = Color.white
        static let tertiaryBackground = Color(red: 0.96, green: 0.96, blue: 0.97) // Slightly warm gray
        
        // Text colors - better contrast
        static let textPrimary = Color(red: 0.05, green: 0.05, blue: 0.05) // Near black
        static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.45) // Medium gray
        static let textTertiary = Color(red: 0.65, green: 0.65, blue: 0.65) // Light gray
        
        // UI elements - refined
        static let border = Color(red: 0.88, green: 0.88, blue: 0.89)
        static let cardBackground = Color.white
        static let shadow = Color.black.opacity(0.08) // Softer shadow
        
        // Surface colors
        static let surface = Color.white
        static let surfaceElevated = Color.white
    }
    
    // MARK: - Gradients (Warm Earthy Tones)
    struct Gradients {
        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondary = LinearGradient(
            colors: [Colors.accent, Colors.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let card = LinearGradient(
            colors: [Colors.cardBackground, Colors.tertiaryBackground],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let glass = LinearGradient(
            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warm = LinearGradient(
            colors: [Colors.accent, Color(red: 0.9, green: 0.7, blue: 0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Typography
    struct Typography {
        // Font weights
        static let thin: Font.Weight = .thin
        static let regular: Font.Weight = .regular
        static let medium: Font.Weight = .medium
        static let semibold: Font.Weight = .semibold
        static let bold: Font.Weight = .bold
        
        // Font sizes with Dynamic Type support
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body.weight(.regular)
        static let callout = Font.callout.weight(.medium)
        static let subheadline = Font.subheadline.weight(.medium)
        static let footnote = Font.footnote.weight(.regular)
        static let caption = Font.caption.weight(.medium)
        static let caption2 = Font.caption2.weight(.regular)
        
        // Letter spacing
        static let tight: CGFloat = -0.5
        static let normal: CGFloat = 0
        static let wide: CGFloat = 0.5
        static let wider: CGFloat = 1.0
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Shadows (Enhanced with Depth)
    struct Shadows {
        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        static let sm = Shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1) // Subtle
        static let md = Shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2) // Medium
        static let lg = Shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4) // Large
        static let xl = Shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8) // Extra large
        
        // Colored shadows for depth
        static let coloredSm = Shadow(color: Colors.primary.opacity(0.1), radius: 3, x: 0, y: 1)
        static let coloredLg = Shadow(color: Colors.primary.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    func glassmorphism() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Gradients.glass)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
    
    func neumorphism(isPressed: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.background)
                    .shadow(
                        color: isPressed ? .black.opacity(0.1) : .black.opacity(0.2),
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? 1 : 4,
                        y: isPressed ? 1 : 4
                    )
                    .shadow(
                        color: isPressed ? .white.opacity(0.1) : .white.opacity(0.7),
                        radius: isPressed ? 1 : 8,
                        x: isPressed ? -1 : -4,
                        y: isPressed ? -1 : -4
                    )
            )
    }
    
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                    )
                    .shadow(
                        color: DesignSystem.Colors.shadow,
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
    }
    
    // New: Minimalist card with subtle shadow
    func minimalistCard(elevation: Shadow = DesignSystem.Shadows.sm) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: elevation.color, radius: elevation.radius, x: elevation.x, y: elevation.y)
            )
    }
    
    // New: Soft card with no border
    func softCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(
                        color: DesignSystem.Colors.shadow,
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
    }
    
    // New: Interactive card with hover states
    func interactiveCard(isPressed: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(
                        color: isPressed ? DesignSystem.Colors.shadow.opacity(0.3) : DesignSystem.Colors.shadow,
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 1 : 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // New: Floating card with elevation
    func floatingCard(elevation: Shadow = DesignSystem.Shadows.md) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(
                        color: elevation.color,
                        radius: elevation.radius,
                        x: elevation.x,
                        y: elevation.y
                    )
            )
    }
    
    // New: Glass morphism card
    func glassCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
    
    func primaryButtonStyle() -> some View {
        self
            .background(DesignSystem.Gradients.primary)
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .background(DesignSystem.Colors.tertiaryBackground)
            .foregroundColor(DesignSystem.Colors.primary)
            .fontWeight(.semibold)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1.5)
            )
    }
    
    // New: Minimal button style
    func minimalButtonStyle() -> some View {
        self
            .foregroundColor(DesignSystem.Colors.primary)
            .fontWeight(.medium)
    }
    
    // New: FAB style
    func fabStyle(size: CGFloat = 56) -> some View {
        self
            .frame(width: size, height: size)
            .background(DesignSystem.Gradients.primary)
            .foregroundColor(.white)
            .clipShape(Circle())
            .shadow(color: DesignSystem.Colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
    }
    
    // New: Animated button with press states
    func animatedButton(isPressed: Bool = false) -> some View {
        self
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // New: Ghost button style
    func ghostButtonStyle() -> some View {
        self
            .foregroundColor(DesignSystem.Colors.primary)
            .fontWeight(.medium)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
            )
    }
    
    // New: Text button style
    func textButtonStyle() -> some View {
        self
            .foregroundColor(DesignSystem.Colors.primary)
            .fontWeight(.medium)
    }
}
