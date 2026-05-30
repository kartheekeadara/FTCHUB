//
//  DesignSystem.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DesignSystem {
    // MARK: - Colors (Warm Earthy Tones - Refined)
    struct Colors {
        // Primary warm brown/orange inspired by UI inspiration - More saturated
        static let primary = dynamicColor(
            light: UIColor(red: 0.91, green: 0.64, blue: 0.35, alpha: 1.0), // #E8A45A
            dark: UIColor(red: 0.91, green: 0.64, blue: 0.35, alpha: 1.0) // #E8A45A
        ) // Rich warm brown
        static let secondary = dynamicColor(
            light: UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0), // #8E8E93
            dark: UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0) // #8E8E93
        ) // Medium gray
        static let accent = dynamicColor(
            light: UIColor(red: 0.91, green: 0.64, blue: 0.35, alpha: 1.0), // #E8A45A
            dark: UIColor(red: 0.91, green: 0.64, blue: 0.35, alpha: 1.0) // #E8A45A
        )  // Golden accent
          /// Success green — #30D158 in dark mode
          static let success = dynamicColor(
              light: UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0),
              dark: UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1.0)
          )
        static let warning = dynamicColor(
            light: UIColor(red: 0.95, green: 0.65, blue: 0.15, alpha: 1.0),
            dark: UIColor(red: 0.98, green: 0.74, blue: 0.33, alpha: 1.0)
        )
        static let error = dynamicColor(
            light: UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0), // #FF453A
            dark: UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0) // #FF453A
        )
        
        // Background colors - clean white and light gray with subtle warmth
        static let background = dynamicColor(
            light: UIColor(red: 0.99, green: 0.988, blue: 0.986, alpha: 1.0),
            dark: UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0) // #0A0A0A
        ) // Warm white / pure black
        static let secondaryBackground = dynamicColor(
            light: UIColor.white,
            dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        )
        static let tertiaryBackground = dynamicColor(
            light: UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0),
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        ) // Slightly warm gray
        
        // Text colors - better contrast
        static let textPrimary = dynamicColor(
            light: UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0),
            dark: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // #FFFFFF
        ) // Near black
        static let textSecondary = dynamicColor(
            light: UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0),
            dark: UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0) // #8E8E93
        ) // Medium gray
        /// Tertiary label — #636366 in dark mode
        static let textTertiary = dynamicColor(
            light: UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0),
            dark: UIColor(red: 0.39, green: 0.39, blue: 0.40, alpha: 1.0)
        )
        
        // UI elements - refined
        static let border = dynamicColor(
            light: UIColor(red: 0.88, green: 0.88, blue: 0.89, alpha: 1.0),
            dark: UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1.0)
        )
        static let cardBackground = dynamicColor(
            light: UIColor.white,
            dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        )
        static let shadow = dynamicColor(
            light: UIColor.black.withAlphaComponent(0.08),
            dark: UIColor.black.withAlphaComponent(0.4)
        ) // Softer shadow
        static let focus = dynamicColor(
            light: UIColor(red: 0.28, green: 0.54, blue: 0.94, alpha: 1.0),
            dark: UIColor(red: 0.48, green: 0.72, blue: 0.98, alpha: 1.0)
        )
        static let highlight = dynamicColor(
            light: UIColor(red: 1.0, green: 0.87, blue: 0.65, alpha: 1.0),
            dark: UIColor(red: 1.0, green: 0.73, blue: 0.55, alpha: 1.0)
        )
        static let backgroundElevated = dynamicColor(
            light: UIColor(red: 0.97, green: 0.95, blue: 0.93, alpha: 1.0),
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        )
        
        // Surface colors
        static let surface = dynamicColor(
            light: UIColor.white,
            dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        )
        static let surfaceElevated = dynamicColor(
            light: UIColor.white,
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        )
        /// Muted section backgrounds (calm hierarchy — Phase 1 design tokens)
        static let surfaceMuted = dynamicColor(
            light: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0),
            dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        )
        /// Hairline / quiet borders
        static let borderSubtle = dynamicColor(
            light: UIColor(red: 0.90, green: 0.90, blue: 0.91, alpha: 1.0),
            dark: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1.0)
        )
        /// 1pt separator between grouped list rows — #3A3A3C
        static let separator = dynamicColor(
            light: UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1.0),
            dark: UIColor(red: 0.23, green: 0.23, blue: 0.24, alpha: 1.0)
        )
        /// Low-saturation brand wash for chips and highlights
        static let accentSoft = dynamicColor(
            light: UIColor(red: 0.98, green: 0.93, blue: 0.88, alpha: 1.0),
            dark: UIColor(red: 0.22, green: 0.16, blue: 0.12, alpha: 1.0)
        )
        /// Subtle orange tinted card wash — 8% opacity orange on dark
        static let orangeTintWash = Color(red: 0.91, green: 0.64, blue: 0.35).opacity(0.08)
        /// Orange border at 20% — for tinted card borders
        static let orangeTintBorder = Color(red: 0.91, green: 0.64, blue: 0.35).opacity(0.20)
        /// Text on filled primary buttons
        static let textOnPrimary = Color.white
        
        private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
            Color(UIColor { trait in
                switch trait.userInterfaceStyle {
                case .dark:
                    return dark
                default:
                    return light
                }
            })
        }
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
    
    struct Elevation {
        enum Level {
            case surface
            case raised
            case modal
            
            var style: ElevationStyle {
                switch self {
                case .surface:
                    return ElevationStyle(
                        background: Colors.surface,
                        stroke: Colors.border.opacity(0.35),
                        shadow: Shadows.none
                    )
                case .raised:
                    return ElevationStyle(
                        background: Colors.cardBackground,
                        stroke: Colors.border.opacity(0.45),
                        shadow: Shadows.md
                    )
                case .modal:
                    return ElevationStyle(
                        background: Colors.backgroundElevated,
                        stroke: Colors.focus.opacity(0.25),
                        shadow: Shadows.lg
                    )
                }
            }
        }
        
        struct ElevationStyle {
            let background: Color
            let stroke: Color
            let shadow: Shadow
        }
    }
    
    struct Motion {
        static let quick = Animation.easeOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.32)
        static let emphasized = Animation.interpolatingSpring(stiffness: 250, damping: 28)
        
        static func spring(response: Double = 0.42, dampingFraction: Double = 0.82) -> Animation {
            .spring(response: response, dampingFraction: dampingFraction, blendDuration: 0.1)
        }
    }
    
    struct Haptics {
        enum NotificationType {
            case success, warning, error
        }
        
        enum ImpactType {
            case light, medium, heavy, soft, rigid
        }
        
        static func notify(_ type: NotificationType) {
            #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred({
                switch type {
                case .success: return .success
                case .warning: return .warning
                case .error: return .error
                }
            }())
            #endif
        }
        
        static func impact(_ type: ImpactType) {
            #if canImport(UIKit)
            let style: UIImpactFeedbackGenerator.FeedbackStyle = {
                switch type {
                case .light: return .light
                case .medium: return .medium
                case .heavy: return .heavy
                case .soft: return .soft
                case .rigid: return .rigid
                }
            }()
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
            #endif
        }
        
        static func selection() {
            #if canImport(UIKit)
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            #endif
        }
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extensions
extension Color {
    /// Converts a color name string to a SwiftUI Color
    /// This is used for converting enum color strings (like "gray", "blue", etc.) to actual Color values
    static func fromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "gray", "grey":
            return .gray
        case "blue":
            return .blue
        case "green":
            return .green
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "cyan":
            return .cyan
        case "mint":
            return .mint
        case "teal":
            return .teal
        case "indigo":
            return .indigo
        default:
            return .gray // Default fallback
        }
    }
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
        self.cardElevation(.raised)
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
    
    func cardElevation(_ level: DesignSystem.Elevation.Level) -> some View {
        modifier(ElevationModifier(level: level))
    }
    
    func focusOutline(_ isFocused: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(isFocused ? DesignSystem.Colors.focus : Color.clear, lineWidth: isFocused ? 2 : 0)
        )
    }
    
    func springyAppear(using animation: Animation = DesignSystem.Motion.standard, delay: Double = 0) -> some View {
        modifier(SpringyAppearModifier(animation: animation, delay: delay))
    }
    
    // Navigation bar styling for consistent appearance
    func standardNavigationBar() -> some View {
        self
            .toolbarBackground(DesignSystem.Colors.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #if os(iOS)
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(DesignSystem.Colors.cardBackground)
                appearance.shadowColor = UIColor(DesignSystem.Colors.border.opacity(0.3))
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            #endif
    }
}

private struct ElevationModifier: ViewModifier {
    let level: DesignSystem.Elevation.Level
    
    func body(content: Content) -> some View {
        let style = level.style
        return content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(style.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(style.stroke, lineWidth: 0.6)
                    )
                    .shadow(color: style.shadow.color,
                            radius: style.shadow.radius,
                            x: style.shadow.x,
                            y: style.shadow.y)
            )
    }
}

private struct SpringyAppearModifier: ViewModifier {
    @State private var isVisible = false
    let animation: Animation
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.98)
            .onAppear {
                withAnimation(animation.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Tab root navigation (leading title + tinted bar)

extension View {
    /// Inline navigation title on a neutral bar. Uses the system title slot so labels are not squeezed to “T…” like a custom leading toolbar item next to the back button.
    func ftchubRootNavHeader(title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.tertiaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
