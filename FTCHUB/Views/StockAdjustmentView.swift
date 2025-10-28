//
//  StockAdjustmentView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct StockAdjustmentView: View {
    let item: InventoryItem
    @EnvironmentObject var inventoryService: InventoryService
    @Environment(\.dismiss) private var dismiss
    
    @State private var adjustmentType: AdjustmentType = .add
    @State private var quantity = ""
    @State private var reason = ""
    @State private var notes = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum AdjustmentType: String, CaseIterable {
        case add = "Add Stock"
        case remove = "Remove Stock"
        case set = "Set Stock"
        
        var icon: String {
            switch self {
            case .add: return "plus.circle.fill"
            case .remove: return "minus.circle.fill"
            case .set: return "equal.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .add: return DesignSystem.Colors.success
            case .remove: return DesignSystem.Colors.warning
            case .set: return DesignSystem.Colors.primary
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "plus.minus")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("Adjust Stock")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Update quantity for \(item.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignSystem.Spacing.lg)
                    
                    // Current Stock Info
                    CurrentStockCard(item: item)
                    
                    // Adjustment Form
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Adjustment Type
                        FormSection(title: "Adjustment Type", icon: "arrow.up.arrow.down") {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(AdjustmentType.allCases, id: \.self) { type in
                                    AdjustmentTypeButton(
                                        type: type,
                                        isSelected: adjustmentType == type
                                    ) {
                                        adjustmentType = type
                                    }
                                }
                            }
                        }
                        
                        // Quantity
                        FormSection(title: "Quantity", icon: "number") {
                            CustomTextField(
                                title: "Amount *",
                                text: $quantity,
                                placeholder: "Enter quantity"
                            )
                            .keyboardType(.numberPad)
                        }
                        
                        // Reason
                        FormSection(title: "Reason", icon: "questionmark.circle") {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                Menu {
                                    Button("Received shipment") { reason = "Received shipment" }
                                    Button("Used in build") { reason = "Used in build" }
                                    Button("Lost or damaged") { reason = "Lost or damaged" }
                                    Button("Returned to vendor") { reason = "Returned to vendor" }
                                    Button("Found in storage") { reason = "Found in storage" }
                                    Button("Other") { reason = "Other" }
                                } label: {
                                    HStack {
                                        Text(reason.isEmpty ? "Select reason" : reason)
                                            .foregroundColor(reason.isEmpty ? .secondary : .primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(DesignSystem.CornerRadius.md)
                                }
                                
                                if reason == "Other" {
                                    CustomTextField(
                                        title: "Custom Reason",
                                        text: $reason,
                                        placeholder: "Enter custom reason"
                                    )
                                }
                            }
                        }
                        
                        // Notes
                        FormSection(title: "Notes", icon: "doc.text") {
                            CustomTextField(
                                title: "Additional Notes",
                                text: $notes,
                                placeholder: "Optional notes about this adjustment",
                                isMultiline: true
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("Adjust Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyAdjustment()
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
        !quantity.isEmpty && !reason.isEmpty && Int(quantity) != nil
    }
    
    private var newQuantity: Int {
        guard let adjustment = Int(quantity) else { return item.quantityOnHand }
        
        switch adjustmentType {
        case .add:
            return item.quantityOnHand + adjustment
        case .remove:
            return max(0, item.quantityOnHand - adjustment)
        case .set:
            return adjustment
        }
    }
    
    private func applyAdjustment() {
        guard isFormValid, let adjustment = Int(quantity) else { return }
        
        Task {
            do {
                try await inventoryService.adjustStock(
                    item: item,
                    adjustment: adjustment,
                    reason: reason
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct CurrentStockCard: View {
    let item: InventoryItem
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Circle()
                    .fill(DesignSystem.Gradients.primary)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: item.categoryIcon)
                            .font(.title3)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text("SKU: \(item.sku)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("\(item.quantityOnHand)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("Current Stock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                StockInfoItem(
                    title: "Low Stock Threshold",
                    value: "\(item.lowStockThreshold)",
                    icon: "exclamationmark.triangle",
                    color: DesignSystem.Colors.warning
                )
                
                Spacer()
                
                StockInfoItem(
                    title: "Unit Cost",
                    value: item.displayPrice,
                    icon: "dollarsign.circle",
                    color: DesignSystem.Colors.success
                )
            }
        }
        .padding()
        .cardStyle()
    }
}

struct AdjustmentTypeButton: View {
    let type: StockAdjustmentView.AdjustmentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(type.color)
                
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    StockAdjustmentView(item: InventoryItem.sample)
        .environmentObject(InventoryService())
        .environmentObject(AuthService())
}
