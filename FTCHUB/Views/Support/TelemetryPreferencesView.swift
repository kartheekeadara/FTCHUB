//
//  TelemetryPreferencesView.swift
//  FTCHUB
//
//  Created by GPT-5 Codex on 11/9/25.
//

import SwiftUI

struct TelemetryPreferencesView: View {
    @Binding var isEnabled: Bool
    @State private var hasInitializedToggle = false
    
    private var lastUpdatedText: String {
        if let date = TelemetryService.shared.lastPreferenceChange {
            let formatted = date.formatted(date: .abbreviated, time: .shortened)
            return String(format: L10n.Telemetry.lastUpdated, formatted)
        } else {
            return L10n.Telemetry.lastUpdatedNever
        }
    }
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: telemetryBinding) {
                    Text(L10n.Telemetry.toggle)
                }
                .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                
                Text(L10n.Telemetry.toggleDescription)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.top, DesignSystem.Spacing.xs)
                
                Text(lastUpdatedText)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Section {
                Label(L10n.Telemetry.collectCrashes, systemImage: "bolt.heart")
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Label(L10n.Telemetry.collectUsage, systemImage: "chart.bar")
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Label(L10n.Telemetry.collectDevice, systemImage: "iphone")
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            } header: {
                Text(L10n.Telemetry.collectSectionTitle)
                    .textCase(.none)
            } footer: {
                Text(L10n.Telemetry.footerNotice)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Section {
                NavigationLink(destination: LegalDocumentView(title: L10n.Legal.privacyPolicyTitle, resourceName: "PrivacyPolicy")) {
                    Label(L10n.Telemetry.openPrivacyPolicy, systemImage: "doc.text.magnifyingglass")
                }
                
                NavigationLink(destination: LegalDocumentView(title: L10n.Legal.supportTitle, resourceName: "SupportGuide")) {
                    Label(L10n.Telemetry.openSupport, systemImage: "envelope")
                }
            } header: {
                Text(L10n.Telemetry.manageSectionTitle)
                    .textCase(.none)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .listRowBackground(DesignSystem.Colors.cardBackground)
        .background(DesignSystem.Colors.background)
        .navigationTitle(L10n.Telemetry.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isEnabled = TelemetryService.shared.isEnabled
            hasInitializedToggle = false
        }
    }
    
    private var telemetryBinding: Binding<Bool> {
        Binding {
            isEnabled
        } set: { newValue in
            if hasInitializedToggle {
                isEnabled = newValue
                DesignSystem.Haptics.selection()
            } else {
                isEnabled = newValue
                hasInitializedToggle = true
            }
        }
    }
}

#if DEBUG
struct TelemetryPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TelemetryPreferencesView(isEnabled: .constant(true))
        }
    }
}
#endif

