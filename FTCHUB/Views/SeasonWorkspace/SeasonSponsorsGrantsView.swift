//
//  SeasonSponsorsGrantsView.swift
//  FTCHUB
//
//  Season workspace destination: Sponsor pipeline and grant radar links.
//

import SwiftUI

struct SeasonSponsorsGrantsView: View {
    @EnvironmentObject var session: SeasonWorkspaceSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                introCard
                
                SeasonHubSectionCard(title: "Sponsor pipeline", icon: "person.2.wave.2", tint: DesignSystem.Colors.accent) {
                    NavigationLink {
                        SponsorPipelineDetailView(store: session.sponsorStore)
                    } label: {
                        SeasonHubLinkRow(
                            title: "Track sponsors",
                            subtitle: sponsorSummary,
                            systemImage: "person.2.wave.2",
                            tint: DesignSystem.Colors.accent
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                SeasonHubSectionCard(title: "Grant radar", icon: "safari", tint: DesignSystem.Colors.secondary) {
                    VStack(spacing: 0) {
                        ForEach(Array(GrantRadar.items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                SeasonHubRowDivider()
                            }
                            Link(destination: item.url) {
                                SeasonHubLinkRow(
                                    title: item.title,
                                    subtitle: item.windowDescription,
                                    systemImage: "safari",
                                    tint: DesignSystem.Colors.secondary,
                                    trailingSystemImage: "arrow.up.right"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .ftchubRootNavHeader(title: "Sponsors & grants")
    }
    
    private var sponsorSummary: String {
        let count = session.sponsorStore.entries.count
        if count == 0 {
            return "Add organizations and track outreach"
        } else {
            return "\(count) sponsor\(count == 1 ? "" : "s") in pipeline"
        }
    }
    
    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Track sponsor outreach and pledges. Grant links open official FIRST resources for season-specific funding opportunities.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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

// MARK: - Sponsor pipeline detail (moved from SeasonOperationsHubView)

struct SponsorPipelineDetailView: View {
    @ObservedObject var store: SponsorPipelineStore
    @State private var draftSponsor: SponsorPipelineEntry?
    
    var body: some View {
        List {
            if store.entries.isEmpty {
                Text("Track sponsors and follow-ups here. Tap + to add an organization.")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            ForEach(store.entries) { entry in
                Button {
                    draftSponsor = entry
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.organizationName)
                            .font(.body.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text(entry.stage)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        if let d = entry.lastContactDate {
                            Text("Last contact: \(d.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    store.remove(id: store.entries[index].id)
                }
            }
        }
        .navigationTitle("Sponsor pipeline")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    draftSponsor = SponsorPipelineEntry(organizationName: "")
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $draftSponsor) { entry in
            SponsorEditorSheet(entry: entry, store: store)
        }
    }
}

struct SponsorEditorSheet: View {
    @State private var entry: SponsorPipelineEntry
    @ObservedObject var store: SponsorPipelineStore
    @Environment(\.dismiss) private var dismiss
    
    private let stages = ["Prospect", "Contacted", "Meeting", "Committed", "Closed"]
    
    init(entry: SponsorPipelineEntry, store: SponsorPipelineStore) {
        var e = entry
        if !["Prospect", "Contacted", "Meeting", "Committed", "Closed"].contains(e.stage) {
            e.stage = "Prospect"
        }
        _entry = State(initialValue: e)
        self.store = store
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Organization", text: $entry.organizationName)
                Picker("Stage", selection: $entry.stage) {
                    ForEach(stages, id: \.self) { Text($0).tag($0) }
                }
                DatePicker("Last contact", selection: Binding(
                    get: { entry.lastContactDate ?? Date() },
                    set: { entry.lastContactDate = $0 }
                ), displayedComponents: .date)
                Toggle("Clear last contact date", isOn: Binding(
                    get: { entry.lastContactDate == nil },
                    set: { if $0 { entry.lastContactDate = nil } else { entry.lastContactDate = Date() } }
                ))
                TextField("Pledge amount (optional)", text: Binding(
                    get: {
                        guard let p = entry.pledgeAmount else { return "" }
                        return "\(p as NSDecimalNumber)"
                    },
                    set: { entry.pledgeAmount = Decimal(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                ))
                .keyboardType(.decimalPad)
                Section("Notes") {
                    TextField("Notes", text: $entry.notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(entry.organizationName.isEmpty ? "New sponsor" : "Edit sponsor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = entry.organizationName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        entry.organizationName = trimmed
                        store.upsert(entry)
                        dismiss()
                    }
                }
            }
        }
    }
}
