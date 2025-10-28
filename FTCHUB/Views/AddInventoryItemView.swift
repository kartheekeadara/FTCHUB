//
//  AddInventoryItemView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct AddInventoryItemView: View {
    @EnvironmentObject var inventoryService: InventoryService
    @Environment(\.dismiss) private var dismiss
    
    @State private var sku = ""
    @State private var name = ""
    @State private var manufacturer = ""
    @State private var partNumber = ""
    @State private var category = ""
    @State private var location = ""
    @State private var quantityOnHand = ""
    @State private var lowStockThreshold = ""
    @State private var unitCost = ""
    @State private var description = ""
    @State private var imageUrl = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let categories = ["Electronics", "Mechanical", "Tools", "Sensors", "Motors", "Wheels", "Other"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("Add New Item")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Add a new item to your inventory")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, DesignSystem.Spacing.lg)
                    
                    // Form
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Basic Information
                        FormSection(title: "Basic Information", icon: "info.circle") {
                            VStack(spacing: DesignSystem.Spacing.md) {
                                CustomTextField(
                                    title: "Item Name *",
                                    text: $name,
                                    placeholder: "e.g., Rev Robotics Expansion Hub"
                                )
                                
                                CustomTextField(
                                    title: "SKU *",
                                    text: $sku,
                                    placeholder: "e.g., FTC-001"
                                )
                                
                                CustomTextField(
                                    title: "Manufacturer",
                                    text: $manufacturer,
                                    placeholder: "e.g., REV Robotics"
                                )
                                
                                CustomTextField(
                                    title: "Part Number",
                                    text: $partNumber,
                                    placeholder: "e.g., REV-31-1153"
                                )
                            }
                        }
                        
                        // Category and Location
                        FormSection(title: "Organization", icon: "folder") {
                            VStack(spacing: DesignSystem.Spacing.md) {
                                CategoryPicker(selectedCategory: $category, categories: categories)
                                
                                CustomTextField(
                                    title: "Location",
                                    text: $location,
                                    placeholder: "e.g., Robot Cart, Parts Bin A"
                                )
                            }
                        }
                        
                        // Stock Information
                        FormSection(title: "Stock Information", icon: "cube.box") {
                            VStack(spacing: DesignSystem.Spacing.md) {
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    CustomTextField(
                                        title: "Quantity on Hand *",
                                        text: $quantityOnHand,
                                        placeholder: "0"
                                    )
                                    .keyboardType(.numberPad)
                                    
                                    CustomTextField(
                                        title: "Low Stock Threshold",
                                        text: $lowStockThreshold,
                                        placeholder: "1"
                                    )
                                    .keyboardType(.numberPad)
                                }
                                
                                CustomTextField(
                                    title: "Unit Cost",
                                    text: $unitCost,
                                    placeholder: "0.00"
                                )
                                .keyboardType(.decimalPad)
                            }
                        }
                        
                        // Additional Information
                        FormSection(title: "Additional Information", icon: "doc.text") {
                            VStack(spacing: DesignSystem.Spacing.md) {
                                CustomTextField(
                                    title: "Description",
                                    text: $description,
                                    placeholder: "Brief description of the item",
                                    isMultiline: true
                                )
                                
                                CustomTextField(
                                    title: "Image URL",
                                    text: $imageUrl,
                                    placeholder: "https://example.com/image.jpg"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !sku.isEmpty && !quantityOnHand.isEmpty
    }
    
    private func saveItem() {
        guard isFormValid else { return }
        
        let newItem = InventoryItem(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!, // TODO: Get from AuthService
            sku: sku,
            name: name,
            manufacturer: manufacturer.isEmpty ? nil : manufacturer,
            partNumber: partNumber.isEmpty ? nil : partNumber,
            category: category.isEmpty ? nil : category,
            location: location.isEmpty ? nil : location,
            quantityOnHand: Int(quantityOnHand) ?? 0,
            lowStockThreshold: Int(lowStockThreshold) ?? 1,
            unitCost: unitCost.isEmpty ? nil : Decimal(string: unitCost),
            description: description.isEmpty ? nil : description,
            imageUrl: imageUrl.isEmpty ? nil : imageUrl,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            do {
                try await inventoryService.createInventoryItem(item: newItem)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding()
        .cardStyle()
    }
}

struct CategoryPicker: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Category")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Menu {
                ForEach(categories, id: \.self) { category in
                    Button(category) {
                        selectedCategory = category
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory.isEmpty ? "Select Category" : selectedCategory)
                        .foregroundColor(selectedCategory.isEmpty ? .secondary : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
    }
}

#Preview {
    AddInventoryItemView()
        .environmentObject(InventoryService())
        .environmentObject(AuthService())
}
