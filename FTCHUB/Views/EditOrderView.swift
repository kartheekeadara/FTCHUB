//
//  EditOrderView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct EditOrderView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    
    @State private var vendor: String
    @State private var orderNumber: String
    @State private var amount: String
    @State private var quantity: String
    @State private var orderDate: Date
    @State private var status: OrderStatus
    @State private var notes: String
    @State private var selectedBudgetId: UUID?
    @State private var expectedDeliveryDate: Date?
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    @EnvironmentObject var inventoryService: InventoryService
    
    init(order: Order) {
        self.order = order
        _vendor = State(initialValue: order.vendor ?? "")
        _orderNumber = State(initialValue: order.orderNumber ?? "")
        _amount = State(initialValue: "\(order.totalAmount)")
        _quantity = State(initialValue: "1") // Default quantity
        _orderDate = State(initialValue: order.orderDate)
        _status = State(initialValue: order.status)
        _notes = State(initialValue: order.notes ?? "")
        _selectedBudgetId = State(initialValue: order.budgetId)
        _expectedDeliveryDate = State(initialValue: order.expectedDeliveryDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Order Information") {
                    TextField("Vendor Name", text: $vendor)
                    TextField("Order Number (Optional)", text: $orderNumber)
                    
                    TextField("Cost", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                    
                    DatePicker("Order Date", selection: $orderDate, displayedComponents: .date)
                }
                
                Section("Budget") {
                    Picker("Budget (Optional)", selection: $selectedBudgetId) {
                        Text("None").tag(UUID?.none)
                        ForEach(financeService.budgets) { budget in
                            Text(budget.name).tag(UUID?.some(budget.id))
                        }
                    }
                }
                
                Section("Delivery Information") {
                    Toggle("Set Expected Delivery Date", isOn: Binding(
                        get: { expectedDeliveryDate != nil },
                        set: { if $0 { expectedDeliveryDate = Date().addingTimeInterval(86400 * 7) } else { expectedDeliveryDate = nil } }
                    ))
                    
                    if let expectedDate = expectedDeliveryDate {
                        DatePicker("Expected Delivery", selection: Binding(
                            get: { expectedDate },
                            set: { expectedDeliveryDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
                
                Section("Status") {
                    Picker("Order Status", selection: $status) {
                        ForEach(OrderStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            .navigationTitle("Edit Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveOrder()
                    }
                    .disabled(isSaving || vendor.isEmpty)
                }
            }
        }
    }
    
    private func saveOrder() {
        guard !vendor.isEmpty else {
            errorMessage = "Vendor name is required"
            return
        }
        
        // Determine total amount
        guard let amountValue = Decimal(string: amount) else {
            errorMessage = "Invalid cost"
            return
        }
        
        // Get quantity (default to 1 if invalid)
        let quantityValue = Int(quantity) ?? 1
        
        // Calculate total amount (cost * quantity)
        let amountDecimal = amountValue * Decimal(quantityValue)
        
        var updatedOrder = order
        updatedOrder.vendor = vendor
        updatedOrder.orderNumber = orderNumber.isEmpty ? nil : orderNumber
        updatedOrder.totalAmount = amountDecimal
        updatedOrder.orderDate = orderDate
        updatedOrder.status = status
        updatedOrder.notes = notes.isEmpty ? nil : notes
        updatedOrder.receiptUrl = nil
        updatedOrder.receiptUrls = nil
        updatedOrder.budgetId = selectedBudgetId
        updatedOrder.budgetCategoryId = nil
        updatedOrder.expectedDeliveryDate = expectedDeliveryDate
        updatedOrder.updatedAt = Date()
        
        isSaving = true
        Task {
            do {
                try await financeService.updateOrder(updatedOrder)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

#Preview {
    EditOrderView(order: Order(
        id: UUID(),
        teamId: UUID(),
        orderNumber: "ORD-001",
        vendor: "REV Robotics",
        totalAmount: 299.99,
        orderDate: Date(),
        status: .pending,
        notes: "Test order",
        receiptUrl: nil,
        receiptUrls: nil,
        budgetId: nil,
        budgetCategoryId: nil,
        expectedDeliveryDate: nil,
        actualDeliveryDate: nil,
        orderItems: nil,
        createdBy: nil,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .environmentObject(FinanceService.shared)
}

