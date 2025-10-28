//
//  EditInventoryItemView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct EditInventoryItemView: View {
    let item: InventoryItem
    @EnvironmentObject var inventoryService: InventoryService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var manufacturer: String
    @State private var partNumber: String
    @State private var category: String
    @State private var location: String
    @State private var quantityOnHand: String
    @State private var lowStockThreshold: String
    @State private var unitCost: String
    @State private var description: String
    @State private var imageUrl: String
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let categories = ["Electronics", "Mechanical", "Tools", "Sensors", "Motors", "Wheels", "Other"]
    
    init(item: InventoryItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _manufacturer = State(initialValue: item.manufacturer ?? "")
        _partNumber = State(initialValue: item.partNumber ?? "")
        _category = State(initialValue: item.category ?? "")
        _location = State(initialValue: item.location ?? "")
        _quantityOnHand = State(initialValue: String(item.quantityOnHand))
        _lowStockThreshold = State(initialValue: String(item.lowStockThreshold))
        _unitCost = State(initialValue: item.unitCost != nil ? String(describing: item.unitCost!) : "")
        _description = State(initialValue: item.description ?? "")
        _imageUrl = State(initialValue: item.imageUrl ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("Edit Item")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Update item information")
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
                                    title: "SKU",
                                    text: .constant(item.sku),
                                    placeholder: "e.g., FTC-001"
                                )
                                .disabled(true)
                                
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
            .navigationTitle("Edit Item")
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
        !name.isEmpty && !quantityOnHand.isEmpty
    }
    
    private func saveItem() {
        guard isFormValid else { return }
        
        let updatedItem = InventoryItem(
            id: item.id,
            teamId: item.teamId,
            sku: item.sku,
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
            createdAt: item.createdAt,
            updatedAt: Date()
        )
        
        Task {
            do {
                try await inventoryService.updateInventoryItem(item: updatedItem)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    EditInventoryItemView(item: InventoryItem.sample)
        .environmentObject(InventoryService())
        .environmentObject(AuthService())
}
