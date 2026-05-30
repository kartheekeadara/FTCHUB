//
//  LandscapeLayoutHelper.swift
//  FTCHUB
//
//  Created for landscape-optimized layouts
//

import SwiftUI

// MARK: - Landscape Layout Container
struct LandscapeLayout<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let portraitContent: Content
    let landscapeContent: Content?
    
    init(@ViewBuilder content: () -> Content) {
        self.portraitContent = content()
        self.landscapeContent = nil
    }
    
    init(
        @ViewBuilder portrait: () -> Content,
        @ViewBuilder landscape: () -> Content
    ) {
        self.portraitContent = portrait()
        self.landscapeContent = landscape()
    }
    
    private var isLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape layout
                if let landscapeContent = landscapeContent {
                    landscapeContent
                } else {
                    portraitContent
                }
            } else {
                // Portrait layout
                portraitContent
            }
        }
    }
}

// MARK: - Two Column Layout Helper
struct TwoColumnLayout<Left: View, Right: View>: View {
    let leftContent: Left
    let rightContent: Right
    let spacing: CGFloat
    
    init(
        spacing: CGFloat = DesignSystem.Spacing.md,
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self.spacing = spacing
        self.leftContent = left()
        self.rightContent = right()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            leftContent
                .frame(maxWidth: .infinity)
            
            rightContent
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Three Column Layout Helper
struct ThreeColumnLayout<Left: View, Middle: View, Right: View>: View {
    let leftContent: Left
    let middleContent: Middle
    let rightContent: Right
    let spacing: CGFloat
    
    init(
        spacing: CGFloat = DesignSystem.Spacing.md,
        @ViewBuilder left: () -> Left,
        @ViewBuilder middle: () -> Middle,
        @ViewBuilder right: () -> Right
    ) {
        self.spacing = spacing
        self.leftContent = left()
        self.middleContent = middle()
        self.rightContent = right()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            leftContent
                .frame(maxWidth: .infinity)
            
            middleContent
                .frame(maxWidth: .infinity)
            
            rightContent
                .frame(maxWidth: .infinity)
        }
    }
}

// Note: AdaptiveGrid is already defined in OrientationHelper.swift

// MARK: - View Extension for Easy Landscape Support
extension View {
    /// Applies landscape-optimized padding
    func adaptivePadding() -> some View {
        GeometryReader { geometry in
            self.padding(
                geometry.size.width > geometry.size.height
                    ? DesignSystem.Spacing.lg
                    : DesignSystem.Spacing.md
            )
        }
    }
}

