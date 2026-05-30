//
//  OrderDetailView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    @State private var showingEditOrder = false
    
    var linkedBudget: Budget? {
        guard let budgetId = order.budgetId else { return nil }
        return financeService.budgets.first { $0.id == budgetId }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    if geometry.size.width > geometry.size.height {
                        // Landscape: Two-column layout
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                orderStatusSection
                                orderInfoSection
                                if let budget = linkedBudget {
                                    budgetInfoSection(budget: budget)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                if let items = order.orderItems, !items.isEmpty {
                                    lineItemsSection
                                }
                                if let notes = order.notes, !notes.isEmpty {
                                    notesSection
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(DesignSystem.Spacing.md)
                    } else {
                        // Portrait: Single column
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    // Status Badge
                    HStack {
                        Spacer()
                        Text(order.status.displayName)
                            .font(.headline)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(Color.fromString(order.status.color).opacity(0.2))
                            .foregroundColor(Color.fromString(order.status.color))
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        Spacer()
                    }
                    
                    // Overdue Warning
                    if order.isOverdue {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignSystem.Colors.warning)
                            Text("Order is overdue")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .padding()
                        .background(DesignSystem.Colors.warning.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    
                    // Order Info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Order Information")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        OrderInfoRow(label: "Vendor", value: order.vendorName)
                        
                        if let orderNumber = order.orderNumber {
                            OrderInfoRow(label: "Order Number", value: orderNumber)
                        }
                        
                        OrderInfoRow(label: "Order Date", value: order.orderDate.formatted(date: .long, time: .omitted))
                        OrderInfoRow(label: "Total Amount", value: "$\(order.totalAmount.formatted())")
                        
                        if let expectedDate = order.expectedDeliveryDate {
                            OrderInfoRow(label: "Expected Delivery", value: expectedDate.formatted(date: .long, time: .omitted))
                        }
                        
                        if let actualDate = order.actualDeliveryDate {
                            OrderInfoRow(label: "Actual Delivery", value: actualDate.formatted(date: .long, time: .omitted))
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    
                    // Budget Information
                    if let budget = linkedBudget {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Budget Information")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            OrderInfoRow(label: "Budget", value: budget.name)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    
                    // Line Items
                    if let items = order.orderItems, !items.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Line Items (\(items.count))")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                ForEach(items) { item in
                                    OrderItemRowView(item: item, showDelete: false)
                                    
                                    if item.id != items.last?.id {
                                        Divider()
                                            .background(DesignSystem.Colors.border)
                                    }
                                }
                            }
                            
                            Divider()
                                .background(DesignSystem.Colors.border)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                            
                            HStack {
                                Text("Subtotal:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("$\(items.reduce(Decimal(0)) { $0 + $1.totalPrice }.formatted())")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            
                            if !order.totalMatchesItems {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(DesignSystem.Colors.warning)
                                    Text("Order total doesn't match line items total")
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.warning)
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    
                    // Receipts
                    if order.hasReceipts {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Receipts")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    ForEach(Array(order.allReceiptUrls.enumerated()), id: \.offset) { index, url in
                                        ReceiptThumbnailView(url: url, onDelete: nil) // No delete in detail view
                                    }
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    
                    // Notes
                    if let notes = order.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text(notes)
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Edit") {
                            showingEditOrder = true
                        }
                        Button("Done") { dismiss() }
                    }
                }
            }
            .sheet(isPresented: $showingEditOrder) {
                EditOrderView(order: order)
                    .environmentObject(financeService)
            }
        }
    }
    
    // MARK: - Landscape Layout Sections
    private var orderStatusSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Spacer()
                Text(order.status.displayName)
                    .font(.headline)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(Color.fromString(order.status.color).opacity(0.2))
                    .foregroundColor(Color.fromString(order.status.color))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                Spacer()
            }
            
            if order.isOverdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("Order is overdue")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding()
                .background(DesignSystem.Colors.warning.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
    }
    
    private var orderInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Order Information")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            OrderInfoRow(label: "Vendor", value: order.vendorName)
            
            if let orderNumber = order.orderNumber {
                OrderInfoRow(label: "Order Number", value: orderNumber)
            }
            
            OrderInfoRow(label: "Order Date", value: order.orderDate.formatted(date: .long, time: .omitted))
            OrderInfoRow(label: "Total Amount", value: "$\(order.totalAmount.formatted())")
            
            if let expectedDate = order.expectedDeliveryDate {
                OrderInfoRow(label: "Expected Delivery", value: expectedDate.formatted(date: .long, time: .omitted))
            }
            
            if let actualDate = order.actualDeliveryDate {
                OrderInfoRow(label: "Actual Delivery", value: actualDate.formatted(date: .long, time: .omitted))
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private func budgetInfoSection(budget: Budget) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Budget Information")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            OrderInfoRow(label: "Budget", value: budget.name)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Line Items")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let items = order.orderItems {
                ForEach(items) { item in
                    HStack {
                        Text(item.description)
                            .font(.subheadline)
                        Spacer()
                        Text("$\(item.totalPrice.formatted())")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            if let notes = order.notes {
                Text(notes)
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct OrderInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    OrderDetailView(
        order: Order(
            id: UUID(),
            teamId: UUID(),
            orderNumber: "ORD-001",
            vendor: "Sample Vendor",
            totalAmount: 100.00,
            orderDate: Date(),
            status: .pending,
            notes: nil,
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
        )
    )
    .environmentObject(FinanceService.shared)
}

