//
//  OrderLineItemsEditor.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct OrderLineItemsEditor: View {
    @Binding var items: [OrderItem]
    var inventoryItems: [InventoryItem] = []
    var onTotalChanged: ((Decimal) -> Void)? = nil
    
    @State private var showingAddItem = false
    @State private var itemToEdit: OrderItem?
    
    var totalFromItems: Decimal {
        items.reduce(Decimal(0)) { $0 + $1.totalPrice }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Line Items")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: { showingAddItem = true }) {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            
            if items.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("No line items")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("Add line items to track individual items in this order")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
            } else {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(items.indices, id: \.self) { index in
                        OrderItemRowView(
                            item: items[index],
                            onDelete: { deleteItem(at: index) },
                            showDelete: true
                        )
                        
                        if index < items.count - 1 {
                            Divider()
                                .background(DesignSystem.Colors.border)
                        }
                    }
                }
                .padding()
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                
                // Total
                HStack {
                    Text("Total from Items:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("$\(totalFromItems.formatted())")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding()
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddEditOrderItemView(
                item: nil,
                inventoryItems: inventoryItems,
                onSave: { newItem in
                    items.append(newItem)
                    updateTotal()
                }
            )
        }
        .sheet(item: $itemToEdit) { item in
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                AddEditOrderItemView(
                    item: item,
                    inventoryItems: inventoryItems,
                    onSave: { updatedItem in
                        items[index] = updatedItem
                        updateTotal()
                    }
                )
            }
        }
        .onChange(of: items.count) { oldValue, newValue in
            updateTotal()
        }
    }
    
    private func deleteItem(at index: Int) {
        items.remove(at: index)
        updateTotal()
    }
    
    private func updateTotal() {
        onTotalChanged?(totalFromItems)
    }
}

// MARK: - Add/Edit Order Item View

struct AddEditOrderItemView: View {
    let item: OrderItem?
    let inventoryItems: [InventoryItem]
    let onSave: (OrderItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var description: String = ""
    @State private var quantity: String = "1"
    @State private var unitPrice: String = ""
    @State private var selectedInventoryItem: InventoryItem?
    @State private var useInventoryItem: Bool = false
    
    init(item: OrderItem?, inventoryItems: [InventoryItem], onSave: @escaping (OrderItem) -> Void) {
        self.item = item
        self.inventoryItems = inventoryItems
        self.onSave = onSave
        
        if let item = item {
            _description = State(initialValue: item.description)
            _quantity = State(initialValue: "\(item.quantity)")
            _unitPrice = State(initialValue: "\(item.unitPrice)")
            if let itemId = item.itemId {
                _selectedInventoryItem = State(initialValue: inventoryItems.first { $0.id == itemId })
                _useInventoryItem = State(initialValue: selectedInventoryItem != nil)
            }
        }
    }
    
    var calculatedTotal: Decimal {
        guard let qty = Int(quantity),
              let price = Decimal(string: unitPrice) else {
            return 0
        }
        return Decimal(qty) * price
    }
    
    var isValid: Bool {
        !description.isEmpty &&
        Int(quantity) != nil && Int(quantity)! > 0 &&
        Decimal(string: unitPrice) != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Information") {
                    Toggle("Link to Inventory Item", isOn: $useInventoryItem)
                    
                    if useInventoryItem {
                        Picker("Inventory Item", selection: $selectedInventoryItem) {
                            Text("None").tag(InventoryItem?.none)
                            ForEach(inventoryItems) { invItem in
                                Text(invItem.name).tag(InventoryItem?.some(invItem))
                            }
                        }
                        .onChange(of: selectedInventoryItem) { oldValue, newValue in
                            if let item = newValue {
                                description = item.name
                                if let cost = item.unitCost {
                                    unitPrice = "\(cost)"
                                }
                            }
                        }
                    }
                    
                    TextField("Description", text: $description)
                    
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.numberPad)
                        
                        TextField("Unit Price", text: $unitPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Calculated") {
                    HStack {
                        Text("Total:")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("$\(calculatedTotal.formatted())")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            }
            .navigationTitle(item == nil ? "Add Line Item" : "Edit Line Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveItem() {
        guard let qty = Int(quantity),
              let price = Decimal(string: unitPrice),
              qty > 0 else {
            return
        }
        
        let total = Decimal(qty) * price
        
        let newItem: OrderItem
        if let existingItem = item {
            newItem = OrderItem(
                id: existingItem.id,
                orderId: existingItem.orderId,
                itemId: selectedInventoryItem?.id,
                description: description,
                quantity: qty,
                unitPrice: price,
                totalPrice: total,
                createdAt: existingItem.createdAt
            )
        } else {
            newItem = OrderItem(
                orderId: UUID(), // Will be updated when order is created
                itemId: selectedInventoryItem?.id,
                description: description,
                quantity: qty,
                unitPrice: price,
                totalPrice: total
            )
        }
        
        onSave(newItem)
        dismiss()
    }
}

#Preview {
    OrderLineItemsEditor(items: .constant(OrderItem.sampleItems))
}

