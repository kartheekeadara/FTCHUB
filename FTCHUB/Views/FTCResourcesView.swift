//
//  FTCResourcesView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI
import UIKit
#if canImport(SafariServices)
import SafariServices
#endif

struct FTCResourcesView: View {
    @StateObject private var resourcesService = ResourcesService.shared
    @State private var viewMode: ViewMode = .interactive
    @State private var selectedResource: FTCResource?
    @State private var showingBrowser = false
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject var authService: AuthService
    
    enum ViewMode: Hashable {
        case interactive
        case traditional
    }
    
    private var usesGuestLayout: Bool {
        authService.isGuestMode
    }
    
    private var segmentMinHeight: CGFloat {
        usesGuestLayout ? 48 : 36
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Header + segment above scrollable content so refreshable / scroll gestures never steal taps from the pill.
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Educational Resources")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text("Guides, flashcards & links")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    // Segment switcher with compact Mobbin-style proportions.
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewMode = .interactive
                            }
                            DesignSystem.Haptics.selection()
                        }) {
                            Text("Flashcards")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(viewMode == .interactive ? DesignSystem.Colors.textOnPrimary : DesignSystem.Colors.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: segmentMinHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(viewMode == .interactive ? DesignSystem.Colors.primary : Color.clear)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewMode = .traditional
                            }
                            DesignSystem.Haptics.selection()
                        }) {
                            Text("Links")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(viewMode == .traditional ? DesignSystem.Colors.textOnPrimary : DesignSystem.Colors.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: segmentMinHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(viewMode == .traditional ? DesignSystem.Colors.primary : Color.clear)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(3)
                    .background(DesignSystem.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
                .zIndex(1)

                Group {
                    if viewMode == .interactive {
                        InteractiveLearningView(usesGuestLayout: usesGuestLayout)
                    } else {
                        traditionalView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(viewMode)
                .refreshable {
                    await refreshResources()
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationBarHidden(true)
            .navigationDestination(for: UUID.self) { resourceId in
                if let resource = resourcesService.resources.first(where: { $0.id == resourceId }) {
                    EducationalResourceDetailView(resource: resource)
                        .navigationBarBackButtonHidden(false)
                }
            }
            .onAppear {
                resourcesService.bindAuthService(authService)
                if authService.isAuthenticated {
                    Task.detached(priority: .utility) {
                        try? await resourcesService.loadBookmarks()
                    }
                }
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        resourcesService.selectedCategory != nil ||
        resourcesService.selectedDifficulty != nil ||
        resourcesService.showOfficialOnly ||
        resourcesService.showFeaturedOnly
    }
    
    // MARK: - Helper Functions
    
    private func refreshResources() async {
        do {
            try await resourcesService.loadResources()
        } catch {
            await MainActor.run {
                resourcesService.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func normalizedURLString(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return t }
        if let u = URL(string: t), u.scheme != nil { return t }
        return "https://\(t)"
    }
    
    private func openResourceURL(_ urlString: String) {
        let normalized = normalizedURLString(urlString)
        guard let url = URL(string: normalized), url.scheme == "http" || url.scheme == "https" else {
            DesignSystem.Haptics.notify(.error)
            return
        }
        
        DesignSystem.Haptics.selection()
        UIApplication.shared.open(url) { success in
            if !success {
                DesignSystem.Haptics.notify(.error)
            }
        }
    }
    
    // Check if resource is FTC Rules & Game Manual (should show detail page)
    private func isRulesResource(_ resource: FTCResource) -> Bool {
        let titleLower = resource.title.lowercased()
        return (titleLower.contains("ftc rules") && titleLower.contains("game manual")) ||
               (titleLower.contains("rules & game manual")) ||
               (resource.category == .rules && resource.isOfficial == true && titleLower.contains("rules"))
    }
    
    // Handle resource tap - navigate to detail if rules, otherwise open in Safari
    private func handleResourceTap(_ resource: FTCResource) {
        DesignSystem.Haptics.selection()
        if isRulesResource(resource) {
            // Navigate to detail page for rules
            navigationPath.append(resource.id)
        } else {
            // Open directly in Safari for all other resources
            openResourceURL(resource.url)
        }
    }
    
    
    // MARK: - Traditional View
    private var traditionalView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Resources by Category
                if !resourcesService.resources.isEmpty {
                    resourcesByCategorySection
                } else if resourcesService.isLoading {
                    EnhancedLoadingView(message: "Loading resources...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else if let errorMessage = resourcesService.errorMessage {
                    ErrorView(
                        error: ErrorHandler.userFriendlyError(
                            from: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]),
                            context: "Loading resources"
                        ),
                        onRetry: {
                            Task {
                                try? await resourcesService.loadResources()
                            }
                        }
                    )
                    .padding()
                } else {
                    EnhancedEmptyStateView(
                        icon: "book.closed",
                        title: "No resources available",
                        message: "Resources will appear here once they're loaded.",
                        actionTitle: nil,
                        action: nil
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(.bottom, 20)
        }
        .tabBarScrollInset()
    }
    
    // MARK: - Resources by Category Section
    private var resourcesByCategorySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            let categories = ResourceCategory.allCases
            ForEach(categories, id: \.self) { category in
                let categoryResources = resourcesService.resources.filter { $0.category == category }
                if !categoryResources.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        // Section header
                        HStack(spacing: 8) {
                            Image(systemName: categoryIcon(for: category))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(categoryColor(for: category))
                            Text(category.displayName.uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .tracking(0.5)
                            Spacer()
                            Text("\(categoryResources.count)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                        VStack(spacing: 0) {
                            ForEach(Array(categoryResources.enumerated()), id: \.element.id) { index, resource in
                                ResourceLinkRow(
                                    resource: resource,
                                    color: categoryColor(for: category),
                                    usesGuestLayout: usesGuestLayout
                                ) {
                                    handleResourceTap(resource)
                                }
                                if index < categoryResources.count - 1 {
                                    Divider()
                                        .background(DesignSystem.Colors.separator)
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(DesignSystem.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    private func categoryIcon(for category: ResourceCategory) -> String {
        switch category {
        case .official: return "checkmark.seal.fill"
        case .rules: return "book.closed.fill"
        case .community: return "person.3.fill"
        case .technical: return "wrench.and.screwdriver.fill"
        case .programming: return "laptopcomputer"
        case .strategy: return "brain.head.profile"
        case .safety: return "shield.fill"
        case .awards: return "trophy.fill"
        case .video: return "play.circle.fill"
        case .parts: return "cube.box.fill"
        }
    }
    
    private func categoryColor(for category: ResourceCategory) -> Color {
        switch category {
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
    
}

// MARK: - Resource Link Row (with domain badge)
private struct ResourceLinkRow: View {
    let resource: FTCResource
    let color: Color
    var usesGuestLayout: Bool = false
    let onTap: () -> Void

    private var domain: String? {
        let raw = resource.url.trimmingCharacters(in: .whitespacesAndNewlines)
        let withScheme = (URL(string: raw)?.scheme != nil) ? raw : "https://\(raw)"
        guard let host = URL(string: withScheme)?.host else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.10))
                        .frame(width: 36, height: 36)
                    Image(systemName: resource.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(resource.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    if let domain {
                        Text(domain)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: usesGuestLayout ? 72 : 56)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Segmented Control
struct CustomSegmentedControl<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [(value: SelectionValue, title: String, icon: String)]
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignSystem.Colors.tertiaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
            
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element.value) { index, option in
                    let isSelected = selection == option.value
                    
                    Button {
                        selection = option.value
                        DesignSystem.Haptics.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: option.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(option.title)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            Group {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    DesignSystem.Colors.primary,
                                                    DesignSystem.Colors.accent
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                        .matchedGeometryEffect(id: "selected", in: animation)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
        }
        .frame(height: 48)
    }
}

// MARK: - Compact Featured Card
struct CompactFeaturedCard: View {
    let resource: FTCResource
    let action: () -> Void
    @State private var isPressed = false
    
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
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    categoryColor.opacity(0.2),
                                    categoryColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: resource.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(categoryColor)
                }
                
                Text(resource.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 140, alignment: .leading)
            }
            .padding(12)
            .frame(width: 164)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isPressed ? 0.02 : 0.05), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(categoryColor.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
}

struct ResourceCardWithExplanation: View {
    let resource: FTCResource
    let action: () -> Void
    @State private var isExpanded = false
    
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
        VStack(alignment: .leading, spacing: 0) {
            // Main card
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: resource.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(categoryColor)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resource.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(resource.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                            .multilineTextAlignment(.leading)
                        
                        // Category badge
                        Text(resource.category.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.2))
                            .foregroundColor(categoryColor)
                            .cornerRadius(6)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            // Expanded content with explanation and subpages
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal)
                    
                    // Explanation section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comprehensive Guide")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            ExplanationTextView(text: resource.explanation ?? resource.description, categoryColor: categoryColor)
                        }
                        .frame(maxHeight: 400)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Subpages section
                    if let subPages = resource.subPages, !subPages.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Related Links")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            ForEach(subPages, id: \.id) { subPage in
                                Link(destination: URL(string: subPage.url)!) {
                                    HStack {
                                        Image(systemName: "link")
                                            .font(.caption)
                                            .foregroundColor(categoryColor)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(subPage.title)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text(subPage.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(categoryColor.opacity(0.05))
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Main link button
                    Button(action: action) {
                        HStack {
                            Image(systemName: "safari")
                                .font(.subheadline)
                            Text("Open Main Resource")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(categoryColor)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.bottom, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// ExplanationTextView is now defined in Views/ExplanationTextView.swift

// ResourceCard, FTCResource, ResourceCategory, ResourceBrowserView, and SafariView
// are now defined in Models/FTCResource.swift

// MARK: - Resource Category Chip
struct ResourceCategoryChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("(\(count))")
                    .font(.caption2)
                    .opacity(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.2) : DesignSystem.Colors.cardBackground)
            .foregroundColor(isSelected ? color : DesignSystem.Colors.textPrimary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : DesignSystem.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Resource Filter Chip
struct ResourceFilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DesignSystem.Colors.cardBackground)
        .foregroundColor(DesignSystem.Colors.textPrimary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Resource Filters View
struct ResourceFiltersView: View {
    @EnvironmentObject var resourcesService: ResourcesService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: Binding(
                        get: { resourcesService.selectedCategory },
                        set: { 
                            DesignSystem.Haptics.selection()
                            resourcesService.selectedCategory = $0 
                        }
                    )) {
                        Text("All").tag(nil as ResourceCategory?)
                        ForEach([ResourceCategory.official, .rules, .community, .technical, .programming, .strategy, .safety, .awards, .video, .parts], id: \.self) { category in
                            Text(category.displayName).tag(category as ResourceCategory?)
                        }
                    }
                }
                
                Section("Difficulty") {
                    Picker("Difficulty", selection: Binding(
                        get: { resourcesService.selectedDifficulty },
                        set: { 
                            DesignSystem.Haptics.selection()
                            resourcesService.selectedDifficulty = $0 
                        }
                    )) {
                        Text("All").tag(nil as ResourceDifficulty?)
                        ForEach([ResourceDifficulty.beginner, .intermediate, .advanced], id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty as ResourceDifficulty?)
                        }
                    }
                }
                
                Section("Options") {
                    Toggle("Official Only", isOn: Binding(
                        get: { resourcesService.showOfficialOnly },
                        set: {
                            DesignSystem.Haptics.selection()
                            resourcesService.showOfficialOnly = $0
                        }
                    ))
                    Toggle("Featured Only", isOn: Binding(
                        get: { resourcesService.showFeaturedOnly },
                        set: {
                            DesignSystem.Haptics.selection()
                            resourcesService.showFeaturedOnly = $0
                        }
                    ))
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        DesignSystem.Haptics.selection()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        DesignSystem.Haptics.impact(.medium)
                        resourcesService.clearFilters()
                    }
                }
            }
        }
    }
}

// MARK: - Resource Card Wrapper (ensures proper isolation)
struct ResourceCardWrapper: View {
    let resource: FTCResource
    
    init(resource: FTCResource) {
        self.resource = resource
        // Force unique identity
        _ = resource.id
        _ = resource.title
    }
    
    var body: some View {
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
        .accessibilityLabel(resource.title)
        .accessibilityHint("Tap to view details about \(resource.title)")
        .id("\(resource.id.uuidString)-\(resource.title)")
    }
}

// MARK: - Enhanced Resource Card
struct EnhancedResourceCard: View {
    let resource: FTCResource
    let onTap: () -> Void
    let onIconTap: () -> Void
    
    @StateObject private var resourcesService = ResourcesService.shared
    @StateObject private var downloadManager = ResourceDownloadManager.shared
    @State private var isBookmarked = false
    @State private var isDownloaded = false
    
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
        Button(action: onTap) {
                HStack(spacing: 16) {
                // Icon - long press to open URL directly
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        categoryColor.opacity(0.2),
                                        categoryColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: resource.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(categoryColor)
                    }
                .onLongPressGesture(minimumDuration: 0.3) {
                    onIconTap()
            }
                    
                // Content
                    VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(resource.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        // Badges row
                        HStack(spacing: 4) {
                            // Featured badge
                            if resource.featured == true {
                                BadgeView(text: "Featured", color: .orange, icon: "star.fill")
                            }
                            
                            // Freshness badge
                            if let lastUpdated = resource.lastUpdated {
                                let daysSince = Calendar.current.dateComponents([.day], from: lastUpdated, to: Date()).day ?? 0
                                if daysSince < 30 {
                                    BadgeView(text: "Updated", color: .green, icon: "clock.fill")
                                }
                            }
                        }
                    }
                        
                        Text(resource.description)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                    // Metadata row
                    HStack(spacing: 12) {
                        // Category badge
                        Text(resource.category.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(categoryColor.opacity(0.15))
                            .foregroundColor(categoryColor)
                            .cornerRadius(4)
                        
                        // Difficulty
                        if let difficulty = resource.difficulty {
                            HStack(spacing: 3) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.caption2)
                                Text(difficulty.displayName)
                                    .font(.caption2)
                            }
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        // Time estimate
                        if let time = resource.estimatedTimeMinutes {
                            HStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                Text("\(time) min")
                                    .font(.caption2)
                            }
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        // Sections count
                        if let subPages = resource.subPages, !subPages.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.caption2)
                                Text("\(subPages.count)")
                                    .font(.caption2)
                            }
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        
                        Spacer()
                        
                        // Download indicator
                        if isDownloaded {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        // Bookmark indicator
                        if isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .font(.caption)
                                .foregroundColor(categoryColor)
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        }
        .buttonStyle(.plain)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(categoryColor.opacity(0.1), lineWidth: 1)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Bookmark action
            Button(action: {
                Task {
                    if isBookmarked {
                        try? await resourcesService.removeBookmark(resource)
                    } else {
                        try? await resourcesService.addBookmark(resource)
                    }
                    isBookmarked = resourcesService.isBookmarked(resource)
                }
            }) {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash.fill" : "bookmark.fill")
            }
            .tint(categoryColor)
            
            // Download action (if URL is a PDF)
            if resource.url.hasSuffix(".pdf") || resource.url.contains(".pdf") {
                Button(action: {
                    guard let url = URL(string: resource.url), url.scheme != nil else {
                        DesignSystem.Haptics.notify(.error)
                        return
                    }
                    Task {
                        DesignSystem.Haptics.selection()
                        do {
                            try await downloadManager.downloadResource(resource, url: url)
                            await MainActor.run {
                                isDownloaded = downloadManager.isDownloaded(resourceId: resource.id)
                                DesignSystem.Haptics.notify(.success)
                            }
                        } catch {
                            await MainActor.run {
                                DesignSystem.Haptics.notify(.error)
                            }
                        }
                    }
                }) {
                    Label(isDownloaded ? "Downloaded" : "Download", systemImage: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                }
                .tint(.blue)
            }
            
            // Share action
            Button(action: {
                guard let url = URL(string: resource.url), url.scheme != nil else {
                    DesignSystem.Haptics.notify(.error)
                    return
                }
                DesignSystem.Haptics.selection()
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.green)
        }
        .onAppear {
            isBookmarked = resourcesService.isBookmarked(resource)
            isDownloaded = downloadManager.isDownloaded(resourceId: resource.id)
        }
        .onChange(of: resourcesService.bookmarkedResources) { _, _ in
            isBookmarked = resourcesService.isBookmarked(resource)
        }
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.system(size: 9, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(4)
    }
}

// MARK: - Compact Resource Card (Grid Layout)
struct CompactResourceCard: View {
    let resource: FTCResource
    let action: () -> Void
    @ObservedObject private var resourcesService = ResourcesService.shared
    @StateObject private var flashcardManager = FlashcardManager.shared
    @EnvironmentObject var authService: AuthService
    @State private var isBookmarked = false
    
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
    
    private var flashcardCount: Int {
        flashcardManager.decks
            .filter { $0.category == resource.category }
            .reduce(0) { $0 + $1.flashcards.count }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Top section with icon and bookmark
                HStack {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        categoryColor.opacity(0.2),
                                        categoryColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: resource.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(categoryColor)
                    }
                    
                    Spacer()
                    
                    // Bookmark button (only show if authenticated)
                    if authService.isAuthenticated {
                        Button(action: {
                            Task { @MainActor in
                                if isBookmarked {
                                    try? await resourcesService.removeBookmark(resource)
                                } else {
                                    try? await resourcesService.addBookmark(resource)
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isBookmarked = resourcesService.isBookmarked(resource)
                                }
                            }
                        }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isBookmarked ? categoryColor : DesignSystem.Colors.textTertiary)
                        }
                        .onAppear {
                            isBookmarked = resourcesService.isBookmarked(resource)
                        }
                    }
                }
                
                // Title
                Text(resource.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Description
                Text(resource.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Bottom badges
                HStack(spacing: 6) {
                    // Category badge
                    Text(resource.category.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(categoryColor.opacity(0.15))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                    
                    // Subpages count
                    if let subPages = resource.subPages, !subPages.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 9))
                            Text("\(subPages.count)")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    // Flashcard count
                    if flashcardCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 9))
                            Text("\(flashcardCount)")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.purple)
                    }
                    
                    Spacer()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
        }
        .buttonStyle(.plain)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.1), lineWidth: 1)
        )
    }
}

