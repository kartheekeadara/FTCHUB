//
//  FinancialDashboardView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct FinancialDashboardView: View {
    @StateObject private var financeService = FinanceService.shared
    @State private var selectedTab: FinanceTab = .overview
    @State private var showingAddOrder = false
    @State private var showingAddBudget = false
    @State private var showingAddVendor = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Finance Tab", selection: $selectedTab) {
                    Text("Overview").tag(FinanceTab.overview)
                    Text("Orders").tag(FinanceTab.orders)
                    Text("Budgets").tag(FinanceTab.budgets)
                    Text("Vendors").tag(FinanceTab.vendors)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    FinanceOverviewView()
                        .environmentObject(financeService)
                        .tag(FinanceTab.overview)
                    
                    OrdersListView()
                        .environmentObject(financeService)
                        .tag(FinanceTab.orders)
                    
                    BudgetsListView()
                        .environmentObject(financeService)
                        .tag(FinanceTab.budgets)
                    
                    VendorsListView()
                        .environmentObject(financeService)
                        .tag(FinanceTab.vendors)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Financial Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddOrder = true }) {
                            Label("Add Order", systemImage: "cart.badge.plus")
                        }
                        Button(action: { showingAddBudget = true }) {
                            Label("Add Budget", systemImage: "dollarsign.circle")
                        }
                        Button(action: { showingAddVendor = true }) {
                            Label("Add Vendor", systemImage: "building.2")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .onAppear {
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                    Task {
                        await financeService.loadFinancialData()
                    }
                }
            }
            .sheet(isPresented: $showingAddOrder) {
                AddOrderView()
                    .environmentObject(financeService)
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView()
                    .environmentObject(financeService)
            }
            .sheet(isPresented: $showingAddVendor) {
                AddVendorView()
                    .environmentObject(financeService)
            }
        }
    }
}

enum FinanceTab {
    case overview, orders, budgets, vendors
}

// MARK: - Finance Overview
struct FinanceOverviewView: View {
    @EnvironmentObject var financeService: FinanceService
    
    var summary: FinancialSummary {
        financeService.getFinancialSummary()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Financial Summary Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    FinanceSummaryCard(
                        title: "Total Budget",
                        value: "$\(summary.totalBudget.formatted())",
                        icon: "dollarsign.circle.fill",
                        color: .blue
                    )
                    
                    FinanceSummaryCard(
                        title: "Total Spent",
                        value: "$\(summary.totalSpent.formatted())",
                        icon: "cart.fill",
                        color: summary.isOverBudget ? .red : .green
                    )
                    
                    FinanceSummaryCard(
                        title: "Remaining",
                        value: "$\(summary.totalRemaining.formatted())",
                        icon: "banknote.fill",
                        color: .purple
                    )
                    
                    FinanceSummaryCard(
                        title: "Pending",
                        value: "$\(summary.pendingAmount.formatted())",
                        icon: "clock.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Budget Usage Progress
                VStack(alignment: .leading, spacing: 12) {
                    Text("Budget Usage")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(Int(summary.percentageUsed))% Used")
                                .font(.subheadline)
                            Spacer()
                            Text("$\(summary.totalSpent.formatted()) / $\(summary.totalBudget.formatted())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: summary.percentageUsed, total: 100)
                            .tint(summary.isOverBudget ? .red : .blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Recent Orders
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Orders")
                            .font(.headline)
                        Spacer()
                        NavigationLink("View All") {
                            OrdersListView()
                                .environmentObject(financeService)
                        }
                        .font(.caption)
                    }
                    
                    if financeService.orders.isEmpty {
                        Text("No orders yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(financeService.getRecentOrders()) { order in
                            OrderRowView(order: order)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Quick Stats
                HStack(spacing: 16) {
                    QuickStatView(title: "Orders", value: "\(summary.orderCount)", icon: "cart")
                    QuickStatView(title: "Budgets", value: "\(summary.budgetCount)", icon: "chart.pie")
                    QuickStatView(title: "Vendors", value: "\(summary.vendorCount)", icon: "building.2")
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Finance Summary Card
struct FinanceSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Quick Stat View
struct QuickStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Order Row View
struct OrderRowView: View {
    let order: Order
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: order.status.icon)
                .foregroundColor(Color(order.status.color))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(order.vendorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(order.orderDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(order.totalAmount.formatted())")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(order.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(order.status.color).opacity(0.2))
                    .foregroundColor(Color(order.status.color))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FinancialDashboardView()
}

