//
//  ErrorView.swift
//  FTCHUB
//
//  Created for Phase 6: Error Handling & User Feedback Improvements
//

import SwiftUI

/// Enhanced error view with user-friendly messages and recovery actions
struct ErrorView: View {
    let error: ErrorHandler.UserFriendlyError
    let onRetry: (() -> Void)?
    
    init(error: ErrorHandler.UserFriendlyError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry ?? error.action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(DesignSystem.Colors.error)
            
            // Title
            Text(error.title)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Message
            Text(error.message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            // Recovery suggestion
            if let suggestion = error.recoverySuggestion {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.warning)
                        
                        Text("Tip")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(DesignSystem.Colors.warning.opacity(0.1))
                )
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            
            // Action button
            if let actionTitle = error.actionTitle, let action = onRetry {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                        Text(actionTitle)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(DesignSystem.Colors.textOnPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .shadow(color: DesignSystem.Colors.shadow.opacity(0.2), radius: 6, x: 0, y: 2)
                }
                .accessibilityHint("Attempts the action again")
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Compact error view for inline use
struct CompactErrorView: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.error)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.error.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Inline validation error view
struct ValidationErrorView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.error)
            
            Text(message)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.error)
        }
        .padding(.top, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}




