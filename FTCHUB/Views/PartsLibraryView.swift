//
//  PartsLibraryView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct PartsLibraryView: View {
    @StateObject private var partsService = PartsLibraryService.shared
    @EnvironmentObject var inventoryService: InventoryService
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedManufacturer: String? = nil
    @State private var showingFilters = false
    @State private var selectedPart: PartTemplate? = nil
    @State private var showingAddSheet = false
    
    var filteredParts: [PartTemplate] {
        var parts = partsService.searchParts(query: searchText)
        
        if let category = selectedCategory {
            parts = parts.filter { $0.category == category }
        }
        
        if let manufacturer = selectedManufacturer {
            parts = parts.filter { $0.manufacturer == manufacturer }
        }
        
        return parts
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search parts...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? .blue : .gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Active Filters
                if hasActiveFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            if let category = selectedCategory {
                                FilterChip(title: category, isSelected: true) {
                                    selectedCategory = nil
                                }
                            }
                            
                            if let manufacturer = selectedManufacturer {
                                FilterChip(title: manufacturer, isSelected: true) {
                                    selectedManufacturer = nil
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                }
                
                // Parts List
                if partsService.isLoading {
                    ProgressView("Loading parts library...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = partsService.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            partsService.loadParts()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredParts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No parts found")
                            .font(.headline)
                        if !searchText.isEmpty || hasActiveFilters {
                            Button("Clear Filters") {
                                searchText = ""
                                selectedCategory = nil
                                selectedManufacturer = nil
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedParts.keys.sorted(), id: \.self) { category in
                            Section(header: Text(category)) {
                                ForEach(groupedParts[category] ?? []) { part in
                                    PartLibraryRow(part: part)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedPart = part
                                            showingAddSheet = true
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Parts Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { selectedManufacturer = "REV Robotics" }) {
                            Label("REV Parts Only", systemImage: "r.circle")
                        }
                        Button(action: { selectedManufacturer = "TETRIX" }) {
                            Label("TETRIX Parts Only", systemImage: "t.circle")
                        }
                        Divider()
                        Button(action: {
                            selectedManufacturer = nil
                            selectedCategory = nil
                        }) {
                            Label("Show All", systemImage: "square.grid.2x2")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FiltersSheet(
                    categories: partsService.categories,
                    manufacturers: partsService.manufacturers,
                    selectedCategory: $selectedCategory,
                    selectedManufacturer: $selectedManufacturer
                )
            }
            .sheet(isPresented: $showingAddSheet) {
                if let part = selectedPart {
                    AddPartFromLibrarySheet(part: part, inventoryService: inventoryService)
                }
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedManufacturer != nil
    }
    
    private var groupedParts: [String: [PartTemplate]] {
        Dictionary(grouping: filteredParts, by: { $0.category })
    }
}

// MARK: - Part Library Row
struct PartLibraryRow: View {
    let part: PartTemplate
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon based on category
            Image(systemName: categoryIcon(for: part.category))
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(part.name)
                    .font(.headline)
                
                Text(part.manufacturer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let description = part.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(part.sku)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if let cost = part.unitCost {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("$\(cost, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Motors": return "bolt.circle.fill"
        case "Servos": return "gear.circle.fill"
        case "Sensors": return "sensor.fill"
        case "Wheels": return "circle.circle.fill"
        case "Electronics": return "cpu"
        case "Structure": return "building.2.fill"
        case "Power": return "battery.100"
        case "Hardware": return "wrench.and.screwdriver.fill"
        case "Power Transmission": return "link.circle.fill"
        case "Gearboxes": return "gearshape.2.fill"
        case "Motion": return "arrow.left.and.right.circle.fill"
        default: return "cube.box.fill"
        }
    }
}

// MARK: - Filters Sheet
struct FiltersSheet: View {
    let categories: [String]
    let manufacturers: [String]
    @Binding var selectedCategory: String?
    @Binding var selectedManufacturer: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Category") {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = selectedCategory == category ? nil : category
                        }) {
                            HStack {
                                Text(category)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Manufacturer") {
                    ForEach(manufacturers, id: \.self) { manufacturer in
                        Button(action: {
                            selectedManufacturer = selectedManufacturer == manufacturer ? nil : manufacturer
                        }) {
                            HStack {
                                Text(manufacturer)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedManufacturer == manufacturer {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Part From Library Sheet
struct AddPartFromLibrarySheet: View {
    let part: PartTemplate
    @ObservedObject var inventoryService: InventoryService
    @Environment(\.dismiss) var dismiss
    
    @State private var quantity: String = "0"
    @State private var location: String = ""
    @State private var isAdding = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Part Details") {
                    LabeledContent("Name", value: part.name)
                    LabeledContent("SKU", value: part.sku)
                    LabeledContent("Manufacturer", value: part.manufacturer)
                    LabeledContent("Category", value: part.category)
                    
                    if let cost = part.unitCost {
                        LabeledContent("Unit Cost") {
                            Text("$\(cost, specifier: "%.2f")")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                if let description = part.description {
                    Section("Description") {
                        Text(description)
                            .font(.body)
                    }
                }
                
                if let specs = part.specifications, !specs.isEmpty {
                    Section("Specifications") {
                        ForEach(Array(specs.keys.sorted()), id: \.self) { key in
                            LabeledContent(key.capitalized, value: specs[key] ?? "")
                        }
                    }
                }
                
                Section("Add to Inventory") {
                    TextField("Initial Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                    
                    TextField("Location (Optional)", text: $location)
                }
            }
            .navigationTitle("Add Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addToInventory()
                    }
                    .disabled(isAdding)
                }
            }
        }
    }
    
    private func addToInventory() {
        isAdding = true
        
        // TODO: Get actual team ID from auth service or team service
        let teamId = UUID() // Placeholder
        
        let initialQuantity = Int(quantity) ?? 0
        let locationText = location.isEmpty ? nil : location
        
        let newItem = PartsLibraryService.shared.createInventoryItem(
            from: part,
            teamId: teamId,
            quantity: initialQuantity,
            location: locationText
        )
        
        Task {
            do {
                try await inventoryService.createInventoryItem(item: newItem)
                await MainActor.run {
                    isAdding = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAdding = false
                }
            }
        }
    }
}

#Preview {
    PartsLibraryView()
        .environmentObject(InventoryService())
}

