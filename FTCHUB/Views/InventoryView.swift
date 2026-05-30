//
//  InventoryView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var teamService: TeamService
    @State private var showingAddItem = false
    @State private var showingFilters = false
    @State private var showingCatalog = false
    @State private var selectedItem: InventoryItem?
    
    var body: some View {
        NavigationStack {
            Group {
                if inventoryService.hasTeamContext {
                    inventoryContent
                } else {
                    TeamAccessRequiredView(featureName: "Inventory")
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                if inventoryService.hasTeamContext {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingCatalog = true
                        } label: {
                            Label("Catalog", systemImage: "book.pages")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddItem = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView()
                .environmentObject(inventoryService)
        }
        .sheet(isPresented: $showingCatalog) {
            PartsCatalogBrowseView()
                .environmentObject(inventoryService)
                .environmentObject(teamService)
        }
        .sheet(item: $selectedItem) { item in
            InventoryItemDetailView(item: item)
                .environmentObject(inventoryService)
        }
        .onAppear {
            Task {
                if inventoryService.hasTeamContext {
                    await inventoryService.loadInventoryItems()
                }
            }
        }
    }
    
    private var inventoryContent: some View {
        VStack(spacing: 0) {
            SearchAndFilterBar(
                searchText: $inventoryService.searchText,
                selectedCategory: $inventoryService.selectedCategory,
                sortOption: $inventoryService.sortOption,
                categories: inventoryService.categories,
                showingFilters: $showingFilters
            )
            
            InventoryQuickStatsSection(
                totalItems: inventoryService.inventoryItems.count,
                lowStockCount: inventoryService.lowStockItems.count,
                outOfStockCount: inventoryService.outOfStockItems.count
            )
            
            if inventoryService.isLoading {
                LoadingView()
            } else if inventoryService.filteredItems.isEmpty {
                EmptyInventoryView(searchText: inventoryService.searchText)
            } else {
                inventoryListView
            }
        }
    }
    
    private var inventoryListView: some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width > geometry.size.height {
                // Landscape: Use grid layout
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                    ], spacing: DesignSystem.Spacing.md) {
                        ForEach(inventoryService.filteredItems) { item in
                            Button(action: { selectedItem = item }) {
                                InventoryItemCard(item: item) {
                                    selectedItem = item
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                }
            } else {
                // Portrait: Use list view
                EnhancedListView(
                    items: inventoryService.filteredItems,
                    onDelete: { item in
                        Task {
                            try await inventoryService.deleteInventoryItem(item: item)
                        }
                    },
                    onEdit: { item in
                        selectedItem = item
                    }
                ) { item in
                    Button(action: { selectedItem = item }) {
                        InventoryItemCard(item: item) {
                            selectedItem = item
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                }
            }
        }
    }
}

// MARK: - Search and Filter Bar
struct SearchAndFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedCategory: String?
    @Binding var sortOption: InventoryService.SortOption
    let categories: [String]
    @Binding var showingFilters: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search inventory...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(DesignSystem.CornerRadius.md)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(categories, id: \.self) { category in
                        FilterChip(
                            title: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                    
                    Button(action: { showingFilters = true }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "line.3.horizontal.decrease")
                            Text("Sort")
                        }
                        .font(.caption)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.sm)
        .background(Color(.systemBackground))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(isSelected ? AnyView(DesignSystem.Gradients.primary) : AnyView(Color(.systemGray6)))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(DesignSystem.CornerRadius.sm)
        }
    }
}

// MARK: - Quick Stats Section
struct InventoryQuickStatsSection: View {
    let totalItems: Int
    let lowStockCount: Int
    let outOfStockCount: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.md) {
                SimpleStatCard(
                    title: "Total Items",
                    value: "\(totalItems)",
                    icon: "cube.box.fill",
                    color: DesignSystem.Colors.primary
                )
                
                SimpleStatCard(
                    title: "Low Stock",
                    value: "\(lowStockCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: DesignSystem.Colors.warning
                )
                
                SimpleStatCard(
                    title: "Out of Stock",
                    value: "\(outOfStockCount)",
                    icon: "xmark.circle.fill",
                    color: DesignSystem.Colors.error
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .padding(.vertical, DesignSystem.Spacing.md)
    }
}

struct SimpleStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Inventory List View
struct InventoryListView: View {
    let items: [InventoryItem]
    @Binding var selectedItem: InventoryItem?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(items) { item in
                    InventoryItemCard(item: item) {
                        selectedItem = item
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
}

struct InventoryItemCard: View {
    let item: InventoryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(DesignSystem.Gradients.primary)
                        .frame(width: 56, height: 56)
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: item.categoryIcon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                // Item Details
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        StockStatusBadge(status: item.stockStatus)
                    }
                    
                    if let manufacturer = item.manufacturer {
                        Text(manufacturer)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text("SKU: \(item.sku)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Qty: \(item.quantityOnHand)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(item.isLowStock ? DesignSystem.Colors.warning : .secondary)
                    }
                    
                    if let location = item.location {
                        HStack {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let cost = item.unitCost {
                                Text(String(format: "$%.2f", cost as NSDecimalNumber))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                    }
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StockStatusBadge: View {
    let status: StockStatus
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: status.icon)
                .font(.caption2)
            
            Text(status.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(Color.fromString(status.color).opacity(0.1))
        .foregroundColor(Color.fromString(status.color))
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

// MARK: - Empty State
struct EmptyInventoryView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            Image(systemName: searchText.isEmpty ? "cube.box" : "magnifyingglass")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Gradients.primary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(searchText.isEmpty ? "No Inventory Items" : "No Results Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(searchText.isEmpty ? 
                     "Start building your inventory by adding your first item." :
                     "Try adjusting your search or filters.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            
            Spacer()
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading inventory...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    InventoryView()
        .environmentObject(InventoryService())
        .environmentObject(TeamService())
}
