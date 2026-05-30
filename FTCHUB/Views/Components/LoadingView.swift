//
//  LoadingView.swift
//  FTCHUB
//
//  Created for Phase 6: Error Handling & User Feedback Improvements
//

import SwiftUI

/// Enhanced loading view with skeleton states
struct EnhancedLoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(DesignSystem.Colors.primary)
                .accessibilityLabel(Text("Loading"))
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Skeleton loading view for list items
struct SkeletonListView: View {
    let count: Int
    
    init(count: Int = 3) {
        self.count = count
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

/// Skeleton card for loading states
struct SkeletonCard: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .opacity(reduceMotion ? 0.85 : (isAnimating ? 0.6 : 1.0))
        .onAppear {
            if reduceMotion {
                isAnimating = false
            } else {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Loading placeholder"))
    }
}

/// Skeleton loading for detail views
struct SkeletonDetailView: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header skeleton
            HStack(spacing: 16) {
                Circle()
                    .fill(DesignSystem.Colors.tertiaryBackground)
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 24)
                        .frame(width: 200)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 16)
                        .frame(width: 150)
                }
            }
            
            // Content skeletons
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 16)
                        .frame(width: 250)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .opacity(reduceMotion ? 0.85 : (isAnimating ? 0.6 : 1.0))
        .onAppear {
            if reduceMotion {
                isAnimating = false
            } else {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Loading placeholder"))
    }
}

/// Full-screen loading overlay
struct LoadingOverlay: View {
    let message: String?
    @Binding var isPresented: Bool
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    if let message = message {
                        Text(message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                .padding(DesignSystem.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(DesignSystem.Colors.cardBackground)
                        .shadow(color: DesignSystem.Colors.shadow, radius: 20, x: 0, y: 10)
                )
            }
            .transition(.opacity)
        }
    }
}

