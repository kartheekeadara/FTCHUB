//
//  OrdersListView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct OrdersListView: View {
    @EnvironmentObject var financeService: FinanceService
    @Binding var selectedTab: FinanceTab
    var isEmbeddedInFinanceDashboard: Bool = false
    
    @State private var searchText = ""
    @State private var selectedStatus: OrderStatus? = nil
    @State private var selectedOrder: Order? = nil
    @State private var showingAddOrder = false
    @State private var showingFilters = false
    @State private var filters = OrderFilters.empty
    @State private var orderToDelete: Order? = nil
    @State private var showingDeleteConfirmation = false
    @State private var isSelecting = false
    @State private var selectedOrderIDs: Set<UUID> = []
    @State private var showingBulkBudgetSheet = false
    @State private var showingBulkStatusSheet = false
    @State private var showingBulkDeleteConfirmation = false
    
    init(
        selectedTab: Binding<FinanceTab> = .constant(.orders),
        isEmbeddedInFinanceDashboard: Bool = false
    ) {
        _selectedTab = selectedTab
        self.isEmbeddedInFinanceDashboard = isEmbeddedInFinanceDashboard
    }
    
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
        
        if filters.isActive {
            if !filters.statuses.isEmpty {
                orders = orders.filter { filters.statuses.contains($0.status) }
            }
            if let dateRange = filters.dateRange {
                orders = orders.filter { dateRange.contains($0.orderDate) }
            }
            if let amountRange = filters.amountRange {
                orders = orders.filter { amountRange.contains($0.totalAmount) }
            }
            if let vendorName = filters.vendor {
                orders = orders.filter { $0.vendor == vendorName }
            }
            if let budgetId = filters.budgetId {
                orders = orders.filter { $0.budgetId == budgetId }
            }
        }
        
        return orders
    }
    
    @ViewBuilder
    private var embeddedFinanceHeader: some View {
        if isEmbeddedInFinanceDashboard {
            FinanceScrollHeader(selectedTab: $selectedTab)
                .environmentObject(financeService)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                landscapeContent
            } else {
                portraitScrollContent
            }
        }
        .searchable(text: $searchText, prompt: "Search orders...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if isEmbeddedInFinanceDashboard {
                        if isSelecting {
                            Button(selectedOrderIDs.count == filteredOrders.count && !filteredOrders.isEmpty ? "Deselect All" : "Select All") {
                                if selectedOrderIDs.count == filteredOrders.count {
                                    selectedOrderIDs.removeAll()
                                } else {
                                    selectedOrderIDs = Set(filteredOrders.map(\.id))
                                }
                            }
                            .font(.subheadline)
                        } else {
                            Button("Select") {
                                isSelecting = true
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    if isSelecting {
                        Button("Done") {
                            isSelecting = false
                            selectedOrderIDs.removeAll()
                        }
                        .font(.subheadline.weight(.semibold))
                    } else if isEmbeddedInFinanceDashboard {
                        if filters.isActive {
                            Button(action: { showingFilters = true }) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        } else {
                            Button(action: { showingFilters = true }) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedOrderIDs.isEmpty {
                bulkActionBar
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView(
                filters: $filters,
                budgets: financeService.budgets,
                vendors: financeService.vendors
            )
        }
        .sheet(isPresented: $showingBulkBudgetSheet) {
            BulkAssignBudgetSheet(
                orderIDs: Array(selectedOrderIDs),
                onComplete: { exitSelectionMode() }
            )
            .environmentObject(financeService)
        }
        .sheet(isPresented: $showingBulkStatusSheet) {
            BulkChangeStatusSheet(
                orderIDs: Array(selectedOrderIDs),
                onComplete: { exitSelectionMode() }
            )
            .environmentObject(financeService)
        }
        .sheet(item: $selectedOrder) { order in
            OrderDetailView(order: order)
                .environmentObject(financeService)
        }
        .alert("Delete Order", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { orderToDelete = nil }
            Button("Delete", role: .destructive) {
                if let order = orderToDelete {
                    Task { await deleteOrder(order) }
                }
                orderToDelete = nil
            }
        } message: {
            if let order = orderToDelete {
                Text("Are you sure you want to delete the order from \(order.vendorName)? This action cannot be undone.")
            }
        }
        .alert("Delete \(selectedOrderIDs.count) Orders", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await bulkDeleteSelected() }
            }
        } message: {
            Text("This will permanently delete the selected orders. This action cannot be undone.")
        }
    }
    
    private var bulkActionBar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Text("\(selectedOrderIDs.count) selected")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Button("Budget") { showingBulkBudgetSheet = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            
            Button("Status") { showingBulkStatusSheet = true }
                .buttonStyle(.bordered)
                .controlSize(.small)
            
            Button("Delete", role: .destructive) { showingBulkDeleteConfirmation = true }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(.ultraThinMaterial)
    }
    
    private var portraitScrollContent: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                embeddedFinanceHeader
                
                if filters.isActive || selectedStatus != nil {
                    activeFiltersCard
                }
                
                if filteredOrders.isEmpty {
                    emptyOrdersView
                } else {
                    ForEach(OrderStatus.allCases, id: \.self) { status in
                        let statusOrders = filteredOrders.filter { $0.status == status }
                        if !statusOrders.isEmpty {
                            orderStatusSection(status: status, orders: statusOrders)
                        }
                    }
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background)
    }
    
    private var landscapeContent: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                embeddedFinanceHeader
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                ], spacing: DesignSystem.Spacing.md) {
                    ForEach(filteredOrders) { order in
                        orderGridCell(order: order)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background)
    }
    
    @ViewBuilder
    private func orderGridCell(order: Order) -> some View {
        let isSelected = selectedOrderIDs.contains(order.id)
        Button {
            if isSelecting {
                toggleSelection(order.id)
            } else {
                selectedOrder = order
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                OrderCardView(order: order)
                    .environmentObject(financeService)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
                    )
                
                if isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                        .padding(DesignSystem.Spacing.sm)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !isSelecting {
                Button { selectedOrder = order } label: { Label("View Details", systemImage: "eye") }
                Button(role: .destructive) {
                    orderToDelete = order
                    showingDeleteConfirmation = true
                } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }
    
    private var activeFiltersCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            if filters.isActive {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Active Filters")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Button("Clear All") {
                        filters = OrderFilters.empty
                        selectedStatus = nil
                    }
                    .font(.caption)
                }
                
                if !filters.statuses.isEmpty {
                    Text("Status: \(filters.statuses.map { $0.displayName }.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                if filters.dateRange != nil {
                    Text("Date: \(filters.dateRange!.startDate.formatted(date: .abbreviated, time: .omitted)) - \(filters.dateRange!.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                if let vendor = filters.vendor {
                    Text("Vendor: \(vendor)")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            if let status = selectedStatus {
                HStack {
                    Text("Filtered by: \(status.displayName)")
                        .font(.caption)
                    Spacer()
                    Button("Clear") { selectedStatus = nil }
                        .font(.caption)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    private var emptyOrdersView: some View {
        EnhancedEmptyStateView(
            icon: "cart",
            title: "No orders found",
            message: searchText.isEmpty && !filters.isActive && selectedStatus == nil
                ? "Create your first order to get started"
                : "Try adjusting your search or filters",
            actionTitle: nil,
            action: nil
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    private func orderStatusSection(status: OrderStatus, orders: [Order]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(status.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
                Text("\(orders.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            VStack(spacing: 0) {
                ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                    orderRowButton(order: order)
                    if index < orders.count - 1 {
                        Divider()
                            .padding(.leading, isSelecting ? 88 : 72)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.border.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    @ViewBuilder
    private func orderRowButton(order: Order) -> some View {
        let isSelected = selectedOrderIDs.contains(order.id)
        Button {
            if isSelecting {
                toggleSelection(order.id)
            } else {
                selectedOrder = order
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                        .frame(width: 28)
                }
                OrderListRow(order: order)
                    .environmentObject(financeService)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !isSelecting {
                Button { selectedOrder = order } label: { Label("Edit", systemImage: "pencil") }
                Button(role: .destructive) {
                    orderToDelete = order
                    showingDeleteConfirmation = true
                } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedOrderIDs.contains(id) {
            selectedOrderIDs.remove(id)
        } else {
            selectedOrderIDs.insert(id)
        }
    }
    
    private func exitSelectionMode() {
        isSelecting = false
        selectedOrderIDs.removeAll()
    }
    
    private func deleteOrder(_ order: Order) async {
        do {
            try await financeService.deleteOrder(order)
        } catch {
            DebugLog.log("Error deleting order: \(error)")
        }
    }
    
    private func bulkDeleteSelected() async {
        let orders = financeService.orders.filter { selectedOrderIDs.contains($0.id) }
        do {
            try await financeService.deleteOrders(orders)
            exitSelectionMode()
        } catch {
            DebugLog.log("Error bulk deleting orders: \(error)")
        }
    }
}

// MARK: - Bulk action sheets

struct BulkAssignBudgetSheet: View {
    @EnvironmentObject var financeService: FinanceService
    @Environment(\.dismiss) private var dismiss
    
    let orderIDs: [UUID]
    var onComplete: () -> Void = {}
    
    @State private var selectedBudgetId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var isSaving = false
    
    private var selectedBudget: Budget? {
        guard let id = selectedBudgetId else { return nil }
        return financeService.budgets.first { $0.id == id }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget") {
                    Picker("Budget", selection: $selectedBudgetId) {
                        Text("None").tag(UUID?.none)
                        ForEach(financeService.budgets) { budget in
                            Text(budget.name).tag(Optional(budget.id))
                        }
                    }
                }
                
                if let budget = selectedBudget, !budget.categories.isEmpty {
                    Section("Category") {
                        Picker("Category", selection: $selectedCategoryId) {
                            Text("None").tag(UUID?.none)
                            ForEach(budget.categories) { category in
                                Text(category.name).tag(Optional(category.id))
                            }
                        }
                    }
                }
                
                Section {
                    Text("\(orderIDs.count) order\(orderIDs.count == 1 ? "" : "s") will be updated.")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .navigationTitle("Move to Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task { await apply() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private func apply() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await financeService.assignOrders(
                orderIds: orderIDs,
                budgetId: selectedBudgetId,
                categoryId: selectedCategoryId
            )
            onComplete()
            dismiss()
        } catch {
            DebugLog.log("Error assigning orders: \(error)")
        }
    }
}

struct BulkChangeStatusSheet: View {
    @EnvironmentObject var financeService: FinanceService
    @Environment(\.dismiss) private var dismiss
    
    let orderIDs: [UUID]
    var onComplete: () -> Void = {}
    
    @State private var selectedStatus: OrderStatus = .ordered
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(OrderStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section {
                    Text("\(orderIDs.count) order\(orderIDs.count == 1 ? "" : "s") will be updated.")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .navigationTitle("Change Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task { await apply() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private func apply() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await financeService.updateOrderStatus(orderIds: orderIDs, status: selectedStatus)
            onComplete()
            dismiss()
        } catch {
            DebugLog.log("Error updating order status: \(error)")
        }
    }
}

// MARK: - Enhanced Order Card View (for landscape grid)
struct OrderCardView: View {
    let order: Order
    @EnvironmentObject var financeService: FinanceService
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.fromString(order.status.color).opacity(0.2),
                                    Color.fromString(order.status.color).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: order.status.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.fromString(order.status.color))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.vendorName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    if let orderNumber = order.orderNumber {
                        Text(orderNumber)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Text(order.status.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.fromString(order.status.color).opacity(0.15))
                    )
                    .foregroundColor(Color.fromString(order.status.color))
            }
            
            Divider()
                .background(DesignSystem.Colors.border.opacity(0.3))
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(order.orderDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Text("$\(order.totalAmount.formatted())")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            if order.isOverdue {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.error)
                    Text("Overdue")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.error)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, 4)
                .background(DesignSystem.Colors.error.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.sm)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.12), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Enhanced Order List Row
struct OrderListRow: View {
    let order: Order
    @EnvironmentObject var financeService: FinanceService
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.fromString(order.status.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: order.status.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.fromString(order.status.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(order.vendorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if order.isOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
                
                if let orderNumber = order.orderNumber {
                    Text(orderNumber)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Text(order.orderDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(order.totalAmount.formatted())")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(order.status.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.fromString(order.status.color).opacity(0.15))
                    )
                    .foregroundColor(Color.fromString(order.status.color))
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

#Preview {
    NavigationView {
        OrdersListView()
            .environmentObject(FinanceService.shared)
    }
}
