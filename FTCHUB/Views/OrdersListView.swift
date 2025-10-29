//
//  OrdersListView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct OrdersListView: View {
    @EnvironmentObject var financeService: FinanceService
    @State private var searchText = ""
    @State private var selectedStatus: OrderStatus? = nil
    @State private var selectedOrder: Order? = nil
    @State private var showingAddOrder = false
    
    var filteredOrders: [Order] {
        var orders = financeService.orders
        
        if !searchText.isEmpty {
            orders = orders.filter { order in
                order.vendorName.lowercased().contains(searchText.lowercased()) ||
                order.orderNumber?.lowercased().contains(searchText.lowercased()) == true
            }
        }
        
        if let status = selectedStatus {
            orders = orders.filter { $0.status == status }
        }
        
        return orders
    }
    
    var body: some View {
        List {
            // Status Filter
            if selectedStatus != nil {
                Section {
                    HStack {
                        Text("Filtered by: \(selectedStatus!.displayName)")
                            .font(.caption)
                        Spacer()
                        Button("Clear") {
                            selectedStatus = nil
                        }
                        .font(.caption)
                    }
                }
            }
            
            // Orders by Status
            ForEach(OrderStatus.allCases, id: \.self) { status in
                let statusOrders = filteredOrders.filter { $0.status == status }
                if !statusOrders.isEmpty {
                    Section(header: Text(status.displayName)) {
                        ForEach(statusOrders) { order in
                            Button(action: {
                                selectedOrder = order
                            }) {
                                OrderListRow(order: order)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            if filteredOrders.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No orders found")
                            .font(.headline)
                        Text("Create your first order to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search orders...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("All Orders") {
                        selectedStatus = nil
                    }
                    Divider()
                    ForEach(OrderStatus.allCases, id: \.self) { status in
                        Button(status.displayName) {
                            selectedStatus = status
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(item: $selectedOrder) { order in
            OrderDetailView(order: order)
                .environmentObject(financeService)
        }
    }
}

// MARK: - Order List Row
struct OrderListRow: View {
    let order: Order
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(Color(order.status.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: order.status.icon)
                    .foregroundColor(Color(order.status.color))
            }
            
            // Order Info
            VStack(alignment: .leading, spacing: 4) {
                Text(order.vendorName)
                    .font(.headline)
                
                if let orderNumber = order.orderNumber {
                    Text(orderNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(order.orderDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text("$\(order.totalAmount.formatted())")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        OrdersListView()
            .environmentObject(FinanceService.shared)
    }
}

