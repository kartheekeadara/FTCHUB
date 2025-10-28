//
//  InventoryItemDetailView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct InventoryItemDetailView: View {
    let item: InventoryItem
    @EnvironmentObject var inventoryService: InventoryService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditView = false
    @State private var showingStockAdjustment = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header Card
                    ItemHeaderCard(item: item)
                    
                    // Stock Information
                    StockInfoCard(item: item)
                    
                    // Item Details
                    ItemDetailsCard(item: item)
                    
                    // Action Buttons
                    ActionButtonsCard(
                        onEdit: { showingEditView = true },
                        onAdjustStock: { showingStockAdjustment = true },
                        onDelete: { showingDeleteConfirmation = true }
                    )
                }
                .padding(DesignSystem.Spacing.md)
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Item") {
                            showingEditView = true
                        }
                        
                        Button("Adjust Stock") {
                            showingStockAdjustment = true
                        }
                        
                        Button("Delete Item", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditInventoryItemView(item: item)
                .environmentObject(inventoryService)
        }
        .sheet(isPresented: $showingStockAdjustment) {
            StockAdjustmentView(item: item)
                .environmentObject(inventoryService)
        }
        .alert("Delete Item", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
    
    private func deleteItem() {
        Task {
            do {
                try await inventoryService.deleteInventoryItem(item: item)
                dismiss()
            } catch {
                // Handle error
            }
        }
    }
}

struct ItemHeaderCard: View {
    let item: InventoryItem
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                // Category Icon
                Circle()
                    .fill(DesignSystem.Gradients.primary)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: item.categoryIcon)
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    if let manufacturer = item.manufacturer {
                        Text(manufacturer)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("SKU: \(item.sku)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StockStatusBadge(status: item.stockStatus)
            }
            
            if let description = item.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .cardStyle()
    }
}

struct StockInfoCard: View {
    let item: InventoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Stock Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: DesignSystem.Spacing.lg) {
                StockInfoItem(
                    title: "On Hand",
                    value: "\(item.quantityOnHand)",
                    icon: "cube.box.fill",
                    color: DesignSystem.Colors.primary
                )
                
                StockInfoItem(
                    title: "Low Stock",
                    value: "\(item.lowStockThreshold)",
                    icon: "exclamationmark.triangle.fill",
                    color: DesignSystem.Colors.warning
                )
                
                StockInfoItem(
                    title: "Unit Cost",
                    value: item.displayPrice,
                    icon: "dollarsign.circle.fill",
                    color: DesignSystem.Colors.success
                )
            }
        }
        .padding()
        .cardStyle()
    }
}

struct StockInfoItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ItemDetailsCard: View {
    let item: InventoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Item Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                if let partNumber = item.partNumber {
                    DetailRow(title: "Part Number", value: partNumber)
                }
                
                if let category = item.category {
                    DetailRow(title: "Category", value: category)
                }
                
                if let location = item.location {
                    DetailRow(title: "Location", value: location)
                }
                
                DetailRow(
                    title: "Created",
                    value: item.createdAt.formatted(date: .abbreviated, time: .omitted)
                )
                
                DetailRow(
                    title: "Last Updated",
                    value: item.updatedAt.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
        .padding()
        .cardStyle()
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ActionButtonsCard: View {
    let onEdit: () -> Void
    let onAdjustStock: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Gradients.primary)
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                
                Button(action: onAdjustStock) {
                    HStack {
                        Image(systemName: "plus.minus")
                        Text("Adjust Stock")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.secondaryBackground)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                    )
                }
            }
            
            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Item")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignSystem.Colors.error)
                .foregroundColor(.white)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    InventoryItemDetailView(item: InventoryItem.sample)
        .environmentObject(InventoryService())
        .environmentObject(AuthService())
}
