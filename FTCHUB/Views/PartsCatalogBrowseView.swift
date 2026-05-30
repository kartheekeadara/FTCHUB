//
//  PartsCatalogBrowseView.swift
//  FTCHUB
//
//  Remote-first parts catalog browser with image-rich grid layout.
//

import SwiftUI
import Kingfisher

struct PartsCatalogBrowseView: View {
    @StateObject private var partsService = PartsLibraryService.shared
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var teamService: TeamService
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var selectedManufacturer: String?
    @State private var selectedCategory: String?
    @State private var selectedPart: PartTemplate?
    @State private var showingFilters = false
    
    private let searchDebounce = 0.3
    
    private var filteredParts: [PartTemplate] {
        var parts = partsService.searchParts(query: debouncedSearchText)
        
        if let manufacturer = selectedManufacturer {
            parts = parts.filter { $0.manufacturer == manufacturer }
        }
        
        if let category = selectedCategory {
            parts = parts.filter { $0.category == category }
        }
        
        return parts
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        heroSection
                        
                        searchBar
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.md)
                        
                        chipSection
                            .padding(.top, DesignSystem.Spacing.md)
                        
                        catalogSourceBadge
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.sm)
                        
                        if case .bundledOnly = partsService.catalogSource {
                            fullCatalogExplainerBanner
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.top, DesignSystem.Spacing.sm)
                        }
                        
                        if partsService.isLoading {
                            loadingView
                        } else if filteredParts.isEmpty {
                            emptyView
                        } else {
                            partsGrid
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.top, DesignSystem.Spacing.md)
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Parts Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await partsService.refreshCatalog() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(partsService.isLoading)
                }
            }
            .sheet(item: $selectedPart) { part in
                PartCatalogDetailSheet(part: part)
                    .environmentObject(inventoryService)
                    .environmentObject(teamService)
            }
            .onChange(of: searchText) { _, newValue in
                debounceSearch(newValue)
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    DesignSystem.Colors.primary.opacity(0.85),
                    DesignSystem.Colors.primary.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 140)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("FTC Parts Catalog")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                
                Text("goBILDA · AndyMark · REV · TETRIX")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("\(partsService.allParts.count) parts from \(partsService.manufacturers.count) vendors")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                TextField("Search parts, SKUs, categories…", text: $searchText)
                    .font(.subheadline)
                    .autocorrectionDisabled()
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        debouncedSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm + 2)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            
            Button { showingFilters = true } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(hasActiveFilters ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
            }
        }
        .sheet(isPresented: $showingFilters) {
            CatalogFiltersSheet(
                categories: partsService.categories,
                manufacturers: partsService.manufacturers,
                selectedCategory: $selectedCategory,
                selectedManufacturer: $selectedManufacturer
            )
        }
    }
    
    // MARK: - Chip Section
    
    private var chipSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(partsService.manufacturers, id: \.self) { mfr in
                    CatalogChip(
                        title: mfr,
                        isSelected: selectedManufacturer == mfr,
                        color: chipColor(for: mfr)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedManufacturer = selectedManufacturer == mfr ? nil : mfr
                        }
                    }
                }
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)
                
                ForEach(partsService.categories.prefix(6), id: \.self) { cat in
                    CatalogChip(
                        title: cat,
                        isSelected: selectedCategory == cat,
                        color: DesignSystem.Colors.secondary
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = selectedCategory == cat ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
    
    // MARK: - Full catalog (remote) explainer
    
    private var fullCatalogExplainerBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "books.vertical")
                    .foregroundColor(DesignSystem.Colors.focus)
                Text("Sample catalog only")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            Text("The app ships a short REV + TETRIX list. A full goBILDA or AndyMark-wide catalog is not loaded by scraping vendor websites (terms of use). Build a JSON manifest from vendor exports or permitted feeds, host it on your CDN, set PARTS_CATALOG_MANIFEST_URL in Secrets, and use part_chunk_urls for large catalogs. See docs/PARTS_CATALOG_ETL.md in the repository.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.focus.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.focus.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Catalog Source Badge
    
    private var catalogSourceBadge: some View {
        HStack(spacing: 6) {
            switch partsService.catalogSource {
            case .bundledOnly:
                Image(systemName: "cube.box")
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                Text("Bundled catalog only")
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            case .remoteAndBundled(let version):
                Image(systemName: "cloud.fill")
                    .foregroundColor(DesignSystem.Colors.success)
                Text("Remote catalog v\(version)")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            case .cachedRemote(let version):
                Image(systemName: "arrow.clockwise.icloud")
                    .foregroundColor(DesignSystem.Colors.warning)
                Text("Cached catalog v\(version)")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .font(.caption2)
    }
    
    // MARK: - Parts Grid
    
    private var partsGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
            GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
        ]
        
        return LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
            ForEach(filteredParts) { part in
                PartCatalogCard(part: part) {
                    selectedPart = part
                }
            }
        }
    }
    
    // MARK: - Loading / Empty
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading catalog…")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
    
    private var emptyView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            Text(debouncedSearchText.isEmpty ? "No parts available" : "No parts match \"\(debouncedSearchText)\"")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if hasActiveFilters {
                Button("Clear filters") {
                    selectedManufacturer = nil
                    selectedCategory = nil
                    searchText = ""
                    debouncedSearchText = ""
                }
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
    
    // MARK: - Helpers
    
    private var hasActiveFilters: Bool {
        selectedManufacturer != nil || selectedCategory != nil
    }
    
    private func chipColor(for manufacturer: String) -> Color {
        switch manufacturer.lowercased() {
        case let m where m.contains("gobilda"):
            return Color(red: 0.0, green: 0.5, blue: 0.8)
        case let m where m.contains("andymark"):
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        case let m where m.contains("rev"):
            return Color(red: 0.95, green: 0.6, blue: 0.1)
        case let m where m.contains("tetrix"):
            return Color(red: 0.3, green: 0.3, blue: 0.7)
        default:
            return DesignSystem.Colors.primary
        }
    }
    
    private func debounceSearch(_ value: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + searchDebounce) {
            if searchText == value {
                debouncedSearchText = value
            }
        }
    }
}

// MARK: - Catalog Chip

private struct CatalogChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(isSelected ? color : DesignSystem.Colors.tertiaryBackground)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Part Catalog Card

private struct PartCatalogCard: View {
    let part: PartTemplate
    let onTap: () -> Void
    
    @State private var resolvedImageURL: URL?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    DesignSystem.Colors.tertiaryBackground
                    
                    if let url = resolvedImageURL {
                        KFImage(url)
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .scaledToFit()
                            .padding(DesignSystem.Spacing.md)
                    } else if let imageURL = part.imageURL, let url = URL(string: imageURL) {
                        KFImage(url)
                            .placeholder {
                                placeholderIcon
                            }
                            .resizable()
                            .scaledToFit()
                            .padding(DesignSystem.Spacing.md)
                    } else {
                        placeholderIcon
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(part.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(part.sku)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    HStack {
                        Text(part.manufacturer)
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        if let cost = part.unitCost {
                            Text("$\(cost, specifier: "%.2f")")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.sm)
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .task {
            resolvedImageURL = await PartsLibraryService.shared.resolvedImageURL(for: part)
        }
    }
    
    private var placeholderIcon: some View {
        Image(systemName: categoryIcon(for: part.category))
            .font(.system(size: 40))
            .foregroundColor(DesignSystem.Colors.textTertiary.opacity(0.5))
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "motors": return "bolt.circle.fill"
        case "servos": return "gear.circle.fill"
        case "sensors": return "sensor.fill"
        case "wheels": return "circle.circle.fill"
        case "electronics": return "cpu"
        case "structure": return "building.2.fill"
        case "power": return "battery.100"
        case "hardware": return "wrench.and.screwdriver.fill"
        case "power transmission": return "link.circle.fill"
        case "gearboxes": return "gearshape.2.fill"
        case "motion": return "arrow.left.and.right.circle.fill"
        default: return "cube.box.fill"
        }
    }
}

// MARK: - Catalog Filters Sheet

private struct CatalogFiltersSheet: View {
    let categories: [String]
    let manufacturers: [String]
    @Binding var selectedCategory: String?
    @Binding var selectedManufacturer: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Manufacturer") {
                    ForEach(manufacturers, id: \.self) { mfr in
                        Button {
                            selectedManufacturer = selectedManufacturer == mfr ? nil : mfr
                        } label: {
                            HStack {
                                Text(mfr)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Spacer()
                                if selectedManufacturer == mfr {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                    }
                }
                
                Section("Category") {
                    ForEach(categories, id: \.self) { cat in
                        Button {
                            selectedCategory = selectedCategory == cat ? nil : cat
                        } label: {
                            HStack {
                                Text(cat)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Spacer()
                                if selectedCategory == cat {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                    }
                }
                
                if selectedCategory != nil || selectedManufacturer != nil {
                    Section {
                        Button("Clear All Filters") {
                            selectedCategory = nil
                            selectedManufacturer = nil
                        }
                        .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PartsCatalogBrowseView()
        .environmentObject(InventoryService())
        .environmentObject(TeamService())
}
