//
//  PrivacyDataProcessingView.swift
//  FTCHUB
//
//  Phase 1: youth / school trust — where data goes (subprocessors overview).
//

import SwiftUI

struct PrivacyDataProcessingView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("Data & subprocessors")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("FTCHUB stores team and account data you enter in the app. Backend sync uses Supabase (hosted PostgreSQL, auth, and storage). When diagnostics are enabled, the app may record anonymized events and errors to Apple Unified Logging on your device.")
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    processorRow(name: "Supabase", role: "Authentication, database, file storage")
                    processorRow(name: "Diagnostics (on-device)", role: "Unified Logging when telemetry is enabled in settings")
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.borderSubtle, lineWidth: 1)
                )
                
                Text("Retention")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text("Keep data only as long as needed for team operations. Account deletion and export flows are described in the Privacy Policy.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("This screen is a summary, not legal advice. For binding terms, see Privacy Policy and Terms of Service.")
                    .font(.footnote)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Data processing")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func processorRow(name: String, role: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text(role)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        PrivacyDataProcessingView()
    }
}
