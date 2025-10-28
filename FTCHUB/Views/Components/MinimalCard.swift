//
//  MinimalCard.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct MinimalCard<Content: View>: View {
    let title: String?
    let icon: String?
    var showBorder: Bool = true
    var elevation: CardElevation = .medium
    @ViewBuilder let content: Content
    
    enum CardElevation {
        case none, low, medium, high
        
        var shadow: Shadow {
            switch self {
            case .none: return DesignSystem.Shadows.none
            case .low: return DesignSystem.Shadows.sm
            case .medium: return DesignSystem.Shadows.md
            case .high: return DesignSystem.Shadows.lg
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header with icon and title
            if let title = title {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(DesignSystem.Gradients.primary)
                    }
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Divider()
                    .background(DesignSystem.Colors.border)
            }
            
            // Content
            content
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(
                            showBorder ? DesignSystem.Colors.border.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: elevation.shadow.color,
                    radius: elevation.shadow.radius,
                    x: elevation.shadow.x,
                    y: elevation.shadow.y
                )
        )
    }
}

// Usage examples:
// MinimalCard(title: "Stats", icon: "chart.bar") { ... }
// MinimalCard(showBorder: false, elevation: .high) { ... }
// MinimalCard { ... } // No title

#Preview {
    VStack(spacing: 20) {
        MinimalCard(title: "Quick Stats", icon: "chart.bar") {
            Text("Card content goes here")
        }
        
        MinimalCard(title: nil, icon: nil, showBorder: false, elevation: .high) {
            Text("Card without border, high elevation")
        }
        
        MinimalCard(title: nil, icon: nil) {
            Text("Simple card without header")
        }
    }
    .padding()
}
