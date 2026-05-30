//
//  SeasonOperationsHubView.swift
//  FTCHUB
//
//  Season OS hub: inventory, sponsors & grants, engineering notebook.
//

import SwiftUI

struct SeasonOperationsHubView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var inventoryService: InventoryService
    
    @StateObject private var session = SeasonWorkspaceSession()
    
    private func syncStoresToTeam() {
        session.updateTeamContext(teamService.currentTeam?.id)
    }
    
    var body: some View {
        Group {
            if teamService.currentTeam != nil {
                hubScrollContent
            } else {
                TeamAccessRequiredView(
                    featureName: "Season workspace",
                    message: "Join or create a team to use inventory, sponsors, and the engineering notebook."
                )
            }
        }
        .ftchubRootNavHeader(title: "Season workspace")
        .onAppear { syncStoresToTeam() }
        .onChange(of: teamService.currentTeam?.id) { _, _ in
            syncStoresToTeam()
        }
    }
    
    private var hubScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                introCard
                
                NavigationLink {
                    InventoryView()
                        .environmentObject(inventoryService)
                        .environmentObject(teamService)
                } label: {
                    SeasonWorkspaceHubRow(
                        title: "Inventory",
                        subtitle: "Parts on hand and stock levels",
                        icon: "shippingbox.fill",
                        tint: DesignSystem.Colors.focus
                    )
                }
                .buttonStyle(.plain)
                .disabled(!inventoryService.hasTeamContext)
                
                NavigationLink {
                    SeasonSponsorsGrantsView()
                        .environmentObject(session)
                } label: {
                    SeasonWorkspaceHubRow(
                        title: "Sponsors & grants",
                        subtitle: "Pipeline and funding links",
                        icon: "person.2.wave.2",
                        tint: DesignSystem.Colors.accent
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    SeasonEngineeringView()
                        .environmentObject(session)
                        .environmentObject(teamService)
                } label: {
                    SeasonWorkspaceHubRow(
                        title: "Engineering",
                        subtitle: "Notebook and run log",
                        icon: "note.text",
                        tint: DesignSystem.Colors.primary
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }
    
    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("October–January rhythm: inventory, sponsors, and build notes — not only event weekends.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Scouting, Competition, and Finance live in the tab bar.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Entry card (Team dashboard)

struct SeasonWorkspaceEntryCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundStyle(DesignSystem.Gradients.primary)
                .frame(width: 44, height: 44)
                .background(DesignSystem.Colors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text("Season workspace")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text("Inventory, sponsors, and engineering notebook.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.backgroundElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
