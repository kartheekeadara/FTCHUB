//
//  AddOrderView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct AddOrderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    
    @State private var vendor = ""
    @State private var orderNumber = ""
    @State private var amount = ""
    @State private var orderDate = Date()
    @State private var status: OrderStatus = .pending
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Order Information") {
                    TextField("Vendor Name", text: $vendor)
                    TextField("Order Number (Optional)", text: $orderNumber)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Order Date", selection: $orderDate, displayedComponents: .date)
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
            }
            .navigationTitle("Add Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveOrder()
                    }
                    .disabled(vendor.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    private func saveOrder() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        
        let newOrder = Order(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            orderNumber: orderNumber.isEmpty ? nil : orderNumber,
            vendor: vendor,
            totalAmount: amountDecimal,
            orderDate: orderDate,
            status: status,
            notes: notes.isEmpty ? nil : notes,
            receiptUrl: nil,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            do {
                try await financeService.createOrder(newOrder)
                dismiss()
            } catch {
                print("Error creating order: \(error)")
            }
        }
    }
}

#Preview {
    AddOrderView()
        .environmentObject(FinanceService.shared)
}

