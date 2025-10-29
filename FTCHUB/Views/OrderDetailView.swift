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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status Badge
                    HStack {
                        Spacer()
                        Text(order.status.displayName)
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(order.status.color).opacity(0.2))
                            .foregroundColor(Color(order.status.color))
                            .cornerRadius(12)
                        Spacer()
                    }
                    
                    // Order Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Information")
                            .font(.headline)
                        
                        OrderInfoRow(label: "Vendor", value: order.vendorName)
                        
                        if let orderNumber = order.orderNumber {
                            OrderInfoRow(label: "Order Number", value: orderNumber)
                        }
                        
                        OrderInfoRow(label: "Order Date", value: order.orderDate.formatted(date: .long, time: .omitted))
                        OrderInfoRow(label: "Total Amount", value: "$\(order.totalAmount.formatted())")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Notes
                    if let notes = order.notes {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Receipt
                    if let receiptUrl = order.receiptUrl {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Receipt")
                                .font(.headline)
                            Link("View Receipt", destination: URL(string: receiptUrl)!)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
    OrderDetailView(order: Order.sample)
        .environmentObject(FinanceService.shared)
}

