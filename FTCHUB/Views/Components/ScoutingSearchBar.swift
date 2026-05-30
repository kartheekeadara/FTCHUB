//
//  ScoutingSearchBar.swift
//  FTCHUB
//
//  Shared search bar for scouting hub pages (Teams, Templates, Reports).
//

import SwiftUI

struct ScoutingSearchBar: View {
    @Binding var text: String
    let placeholder: String
    var isEmbeddedInScoutingHub: Bool = false
    var onClear: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(
                    text.isEmpty
                        ? DesignSystem.Colors.textTertiary
                        : DesignSystem.Colors.primary
                )
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button {
                    text = ""
                    onClear?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(
                    text.isEmpty
                        ? DesignSystem.Colors.borderSubtle.opacity(0.5)
                        : DesignSystem.Colors.primary.opacity(0.35),
                    lineWidth: 1
                )
        )
        .padding(.top, isEmbeddedInScoutingHub ? DesignSystem.Spacing.lg : 0)
    }
}
