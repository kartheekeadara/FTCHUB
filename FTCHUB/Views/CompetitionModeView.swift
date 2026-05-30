//
//  CompetitionModeView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

struct CompetitionModeView: View {
    @EnvironmentObject var scheduleService: ScheduleService
    @State private var selectedTab: CompetitionTab = .schedule
    
    var body: some View {
        NavigationStack {
        if scheduleService.hasTeamContext {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Match Status
                    CurrentMatchCard(match: scheduleService.upcomingMatch())
                        .padding(.horizontal)
                    
                    // Resources - Featured Section (Always Visible)
                    FeaturedResourcesCard {
                        selectedTab = .resources
                    }
                    .padding(.horizontal)
                    
                    // Quick Access Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        QuickActionButton(icon: "calendar", title: "Schedule", color: .blue) {
                            selectedTab = .schedule
                        }
                        
                        QuickActionButton(icon: "checklist", title: "Pre-Match", color: .green) {
                            selectedTab = .preMatch
                        }
                        
                        QuickActionButton(icon: "person.3.fill", title: "Alliance", color: .purple) {
                            selectedTab = .alliance
                        }
                        
                        QuickActionButton(icon: "phone.fill", title: "Contacts", color: .red) {
                            selectedTab = .contacts
                        }
                    }
                    .padding(.horizontal)
                    
                    // Tab Content
                    switch selectedTab {
                    case .schedule:
                        MatchScheduleSection()
                    case .preMatch:
                        PreMatchChecklistSection()
                    case .alliance:
                        AllianceInfoSection()
                    case .contacts:
                        EmergencyContactsSection()
                    case .resources:
                        ResourcesSection()
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Competition Mode")
            .navigationBarTitleDisplayMode(.large)
        } else {
            TeamAccessRequiredView(featureName: "Competition Mode")
                .navigationTitle("Competition Mode")
        }
        }
    }
}

// MARK: - Current Match Card
struct CurrentMatchCard: View {
    let match: Match?
    
    var timeUntilMatch: String {
        guard let scheduled = match?.scheduledTime else {
            return "No match scheduled"
        }
        let interval = scheduled.timeIntervalSinceNow
        if interval < 0 {
            return "Match in progress"
        }
        let minutes = Int(interval / 60)
        return "\(minutes) min"
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Next Match")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(match?.matchNumber ?? "—")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("Time Until")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(timeUntilMatch)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            Divider()
                .background(DesignSystem.Colors.border.opacity(0.3))
            
            HStack(spacing: DesignSystem.Spacing.md) {
                InfoPill(icon: "clock", text: match?.scheduledTime.formatted(date: .omitted, time: .shortened) ?? "—")
                InfoPill(icon: "location", text: match?.location ?? "TBD")
                InfoPill(icon: "person.2", text: match?.allianceColor.displayName ?? "Alliance")
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.primary.opacity(0.08),
                    DesignSystem.Colors.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.primary.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Info Pill
struct InfoPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.primary)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

// MARK: - Featured Resources Card
struct FeaturedResourcesCard: View {
    @StateObject private var resourcesService = ResourcesService.shared
    @State private var topResources: [FTCResource] = []
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Main Card Content
                HStack(spacing: 18) {
                    // Large Icon with Gradient
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.25),
                                        Color.orange.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.orange.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("Educational Resources")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            // Badge
                            Text("NEW")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }
                        
                        Text("Comprehensive FTC guides, tutorials, and best practices")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(2)
                        
                        // Resource Count
                        if !topResources.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange.opacity(0.8))
                                Text("\(topResources.count)+ Resources Available")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.orange.opacity(0.7))
                }
                .padding(24)
                
                // Preview of Top Resources (if available)
                if !topResources.isEmpty {
                    Divider()
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(topResources.prefix(3)) { resource in
                                ResourcePreviewChip(resource: resource)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.12),
                                Color.orange.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.4),
                                        Color.orange.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
            )
            .shadow(color: Color.orange.opacity(0.2), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .task {
            await loadTopResources()
        }
    }
    
    private func loadTopResources() async {
        // Load resources directly from service without database operations
        // This ensures fast loading without database errors
        do {
            try await resourcesService.loadResources()
            topResources = Array(resourcesService.resources.prefix(6))
        } catch {
            // If service fails, resources will be empty - that's okay
            // The card will still show but without resource count
        }
    }
}

// MARK: - Resource Preview Chip
struct ResourcePreviewChip: View {
    let resource: FTCResource
    
    private var categoryColor: Color {
        switch resource.category {
        case .official: return .blue
        case .rules: return .purple
        case .community: return .green
        case .technical: return .orange
        case .programming: return .indigo
        case .strategy: return .pink
        case .safety: return .red
        case .awards: return .yellow
        case .video: return .red
        case .parts: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: resource.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(categoryColor)
                .frame(width: 20)
            
            Text(resource.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(categoryColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(color: DesignSystem.Colors.shadow.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Match Schedule Section
struct MatchScheduleSection: View {
    @EnvironmentObject var scheduleService: ScheduleService
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(DesignSystem.Colors.primary)
            Text("Today's Matches")
                .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            let matches = Array(scheduleService.matches(on: Date()).prefix(3))
            
            if !matches.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(matches, id: \.id) { match in
                    MatchSummaryRow(match: match)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }
}

struct MatchSummaryRow: View {
    let match: Match
    
    private var allianceAccent: Color {
        match.allianceColor == .red ? .red : .blue
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Match #\(match.matchNumber)")
                    .font(.headline)
                Text(match.scheduledTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(match.location ?? "TBD")
                    .font(.caption)
                Text(match.allianceColor.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(allianceAccent.opacity(0.15))
                    .foregroundColor(allianceAccent)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Pre-Match Checklist Section
struct PreMatchChecklistSection: View {
    @State private var checklistItems: [ChecklistItem] = [
        ChecklistItem(title: "Robot inspection passed", isCompleted: true),
        ChecklistItem(title: "Battery fully charged", isCompleted: true),
        ChecklistItem(title: "Controllers paired", isCompleted: false),
        ChecklistItem(title: "Autonomous tested", isCompleted: false),
        ChecklistItem(title: "Alliance strategy discussed", isCompleted: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pre-Match Checklist")
                    .font(.headline)
                Spacer()
                Text("\(checklistItems.filter(\.isCompleted).count)/\(checklistItems.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ForEach($checklistItems) { $item in
                ChecklistRow(item: $item)
                    .padding(.horizontal)
            }
        }
    }
}

struct ChecklistRow: View {
    @Binding var item: ChecklistItem
    
    var body: some View {
        Button(action: {
            item.isCompleted.toggle()
        }) {
            HStack {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title3)
                
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .strikethrough(item.isCompleted)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Alliance Info Section
struct AllianceInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alliance Partners")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                AlliancePartnerCard(teamNumber: "1234", role: "Captain", strengths: ["Auto", "Endgame"])
                AlliancePartnerCard(teamNumber: "5678", role: "Partner", strengths: ["TeleOp", "Defense"])
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Notes")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text("• Focus on autonomous points\n• Captain handles specimen placement\n• Partner plays defense in TeleOp")
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }
}

struct AlliancePartnerCard: View {
    let teamNumber: String
    let role: String
    let strengths: [String]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Team \(teamNumber)")
                    .font(.headline)
                Text(role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(strengths, id: \.self) { strength in
                    Text(strength)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Emergency Contacts Section
struct EmergencyContactsSection: View {
    let contacts = [
        CompetitionContact(name: "Head Coach", phone: "(555) 123-4567", role: "Primary"),
        CompetitionContact(name: "Event Coordinator", phone: "(555) 987-6543", role: "Event Staff"),
        CompetitionContact(name: "Technical Advisor", phone: "(555) 456-7890", role: "Support")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .font(.headline)
                .padding(.horizontal)
            
                ForEach(contacts) { contact in
                    CompetitionContactRow(contact: contact)
                        .padding(.horizontal)
                }
        }
    }
}

struct CompetitionContactRow: View {
    let contact: CompetitionContact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if let url = URL(string: "tel://\(contact.phone.filter { $0.isNumber })") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text(contact.phone)
                        .font(.subheadline)
                    Image(systemName: "phone.fill")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Resources Section
struct ResourcesSection: View {
    @StateObject private var resourcesService = ResourcesService.shared
    @State private var resources: [FTCResource] = []
    @State private var isLoading = false
    @State private var selectedResource: FTCResource?
    @State private var showingBrowser = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header with Navigation Link
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.25),
                                        Color.orange.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.orange.opacity(0.2), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FTC Educational Resources")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Comprehensive guides, tutorials, and best practices")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Quick Stats
                if !resources.isEmpty {
                    HStack(spacing: 20) {
                        ResourceStatBadge(icon: "book.fill", value: "\(resources.count)", label: "Resources")
                        ResourceStatBadge(icon: "square.grid.2x2.fill", value: "\(resources.compactMap { $0.subPages?.count }.reduce(0, +))", label: "Topics")
                        ResourceStatBadge(icon: "rectangle.stack.fill", value: "6", label: "Categories")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // Content
            if resources.isEmpty && !isLoading {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Loading FTC Resources...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Load Resources") {
                        Task {
                            await loadResources()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(.vertical, 40)
            } else if resources.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No resources available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(resources.prefix(6)) { resource in
                        NavigationLink {
                            EducationalResourceDetailView(resource: resource)
                        } label: {
                            EnhancedResourceCard(
                                resource: resource,
                                onTap: {},
                                onIconTap: {
                                    if let url = URL(string: resource.url) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            if resources.isEmpty {
                await loadResources()
            }
        }
        .sheet(isPresented: $showingBrowser) {
            if let resource = selectedResource {
                ResourceBrowserView(resource: resource)
            }
        }
    }
    
    private func loadResources() async {
        // If resources are already loaded in ResourcesService, use them immediately
        if !resourcesService.resources.isEmpty {
            await MainActor.run {
                resources = resourcesService.resources
            }
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await resourcesService.loadResources()
            await MainActor.run {
                resources = resourcesService.resources
            }
        } catch {
            DebugLog.log(" Failed to load resources: \(error.localizedDescription)")
            // Even if database loading fails, use whatever resources are available
            await MainActor.run {
                resources = resourcesService.resources
            }
        }
    }
}

// ResourceCard, FTCResource, ResourceCategory, ResourceBrowserView, and SafariView
// are now defined in Models/FTCResource.swift

// MARK: - Supporting Types
enum CompetitionTab {
    case schedule, preMatch, alliance, contacts, resources
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    var isCompleted: Bool
}

struct CompetitionContact: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let role: String
}

// MARK: - Resource Stat Badge
struct ResourceStatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.orange.opacity(0.8))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CompetitionModeView()
        .environmentObject(ScheduleService())
}

