//
//  FinanceService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class FinanceService: ObservableObject {
    static let shared = FinanceService()
    
    @Published var budgets: [Budget] = []
    @Published var orders: [Order] = []
    @Published var vendors: [Vendor] = []
    @Published var budgetTemplates: [BudgetTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// Set after a successful full load for the active team (Phase 1: visibility of freshness).
    @Published private(set) var lastFinancialDataSyncAt: Date?
    @Published private(set) var activeTeamId: UUID?
    
    @Published var enableBudgetAlerts: Bool
    @Published var budgetAlertThreshold: Int
    @Published var enableSpendingAlerts: Bool
    @Published var spendingAlertLimit: Double
    @Published var autoCategorizeOrders: Bool
    
    private let supabase = SupabaseService.shared.client
    private let localStorage = LocalStorage.shared
    private let defaults = UserDefaults.standard
    private let alertManager = BudgetAlertManager.shared
    
    private enum PreferenceKey {
        static let budgetAlerts = "finance.pref.budgetAlerts"
        static let budgetAlertThreshold = "finance.pref.budgetThreshold"
        static let spendingAlerts = "finance.pref.spendingAlerts"
        static let spendingLimit = "finance.pref.spendingLimit"
        static let autoCategorize = "finance.pref.autoCategorize"
    }
    
    private init() {
        let savedBudgetAlerts = defaults.object(forKey: PreferenceKey.budgetAlerts) as? Bool
        self.enableBudgetAlerts = savedBudgetAlerts ?? true
        let savedBudgetThreshold = defaults.object(forKey: PreferenceKey.budgetAlertThreshold) as? Int ?? 15
        self.budgetAlertThreshold = max(5, savedBudgetThreshold)
        let savedSpendingAlerts = defaults.object(forKey: PreferenceKey.spendingAlerts) as? Bool
        self.enableSpendingAlerts = savedSpendingAlerts ?? false
        let savedLimit = defaults.object(forKey: PreferenceKey.spendingLimit) as? Double ?? 250
        self.spendingAlertLimit = max(50, savedLimit)
        let savedAutoCategorize = defaults.object(forKey: PreferenceKey.autoCategorize) as? Bool
        self.autoCategorizeOrders = savedAutoCategorize ?? true
        
        // Load sample data for preview/demo mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            loadSampleData()
        }
    }
    
    // MARK: - Data Loading
    
    func updateTeamContext(teamId: UUID?) {
        guard activeTeamId != teamId else { return }
        activeTeamId = teamId
        if teamId == nil {
            loadSampleData()
        } else {
            Task { await loadFinancialData() }
        }
    }
    
    func loadFinancialData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let teamId = activeTeamId else {
                loadSampleData()
                return
            }
            
            // Load orders
            var loadedOrders: [Order] = try await supabase
                .from("orders")
                .select()
                .eq("team_id", value: teamId)
                .order("order_date", ascending: false)
                .execute()
                .value
            
            // Load order items for each order
            for index in loadedOrders.indices {
                let orderItems: [OrderItem] = try await supabase
                    .from("order_items")
                    .select()
                    .eq("order_id", value: loadedOrders[index].id)
                    .execute()
                    .value
                loadedOrders[index].orderItems = orderItems.isEmpty ? nil : orderItems
            }
            
            self.orders = loadedOrders
            
            // Load vendors
            let loadedVendors: [Vendor] = try await supabase
                .from("vendors")
                .select()
                .eq("team_id", value: teamId)
                .order("name", ascending: true)
                .execute()
                .value
            
            self.vendors = loadedVendors
            
            // Update vendor performance after loading
            updateVendorPerformance()
            
            // Load budgets
            let loadedBudgets: [Budget] = try await supabase
                .from("budgets")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.budgets = loadedBudgets
            
            // Load budget templates - table may not exist, so catch error gracefully
            do {
                let loadedTemplates: [BudgetTemplate] = try await supabase
                    .from("budget_templates")
                    .select()
                    .eq("team_id", value: teamId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                self.budgetTemplates = loadedTemplates
            } catch {
                // Budget templates table doesn't exist yet, use empty array
                self.budgetTemplates = []
            }
            
            // Update alerts after loading data
            let preferences = AlertPreferences(
                enableBudgetAlerts: enableBudgetAlerts,
                budgetAlertThreshold: budgetAlertThreshold,
                enableSpendingAlerts: enableSpendingAlerts,
                spendingAlertLimit: spendingAlertLimit
            )
            alertManager.updateAlerts(budgets: budgets, orders: orders, preferences: preferences)
            
            lastFinancialDataSyncAt = Date()
            errorMessage = nil
        } catch {
            DebugLog.log("Finance load failed: \(error)")
            if activeTeamId != nil {
                errorMessage = "Couldn’t refresh finances. Check your connection and try again."
                // Keep existing budgets/orders/vendors on screen when possible (no silent wipe).
            } else {
                loadSampleData()
                errorMessage = nil
            }
        }
    }
    
    private func loadSampleData() {
        // Sample data removed - using empty arrays
        self.budgets = []
        self.orders = []
        self.vendors = []
        self.budgetTemplates = []
    }
    
    func savePreferences() {
        defaults.set(enableBudgetAlerts, forKey: PreferenceKey.budgetAlerts)
        defaults.set(budgetAlertThreshold, forKey: PreferenceKey.budgetAlertThreshold)
        defaults.set(enableSpendingAlerts, forKey: PreferenceKey.spendingAlerts)
        defaults.set(spendingAlertLimit, forKey: PreferenceKey.spendingLimit)
        defaults.set(autoCategorizeOrders, forKey: PreferenceKey.autoCategorize)
    }
    
    // MARK: - Budget Operations
    
    func createBudget(_ budget: Budget) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            _ = try InputValidator.MoneyAmountInput(amount: budget.totalAmount)
            _ = try InputValidator.VendorNameInput(budget.name)
            
            // Validate budget data before inserting
            guard budget.totalAmount > 0 else {
                let error = NSError(domain: "FinanceService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Budget amount must be greater than zero"])
                errorMessage = error.localizedDescription
                throw error
            }
            
            guard budget.startDate < budget.endDate else {
                let error = NSError(domain: "FinanceService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Start date must be before end date"])
                errorMessage = error.localizedDescription
                throw error
            }
            
            try await supabase
                .from("budgets")
                .insert(budget)
                .execute()
            await loadFinancialData()
            updateAlerts()
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = errorMsg
            
            // Provide more specific error messages
            if errorMsg.contains("violates") || errorMsg.contains("constraint") {
                errorMessage = "Invalid budget data. Please check all fields and try again."
            } else if errorMsg.contains("network") || errorMsg.contains("connection") {
                errorMessage = "Network error. Please check your connection and try again."
            }
            
            throw error
        }
    }
    
    func updateBudget(_ budget: Budget) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("budgets")
                .update(budget)
                .eq("id", value: budget.id)
                .execute()
            await loadFinancialData()
            updateAlerts()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteBudget(_ budget: Budget) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("budgets")
                .delete()
                .eq("id", value: budget.id)
                .execute()
            await loadFinancialData()
            updateAlerts()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Alert Management
    
    private func updateAlerts() {
        let preferences = AlertPreferences(
            enableBudgetAlerts: enableBudgetAlerts,
            budgetAlertThreshold: budgetAlertThreshold,
            enableSpendingAlerts: enableSpendingAlerts,
            spendingAlertLimit: spendingAlertLimit
        )
        alertManager.updateAlerts(budgets: budgets, orders: orders, preferences: preferences)
    }
    
    var activeAlerts: [BudgetAlert] {
        alertManager.activeAlerts
    }
    
    func dismissAlert(_ alert: BudgetAlert) {
        alertManager.dismissAlert(alert)
    }
    
    // MARK: - Order Operations
    
    func createOrder(_ order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            _ = try InputValidator.MoneyAmountInput(amount: order.totalAmount)
            if let notes = order.notes {
                _ = try InputValidator.FinanceNotesInput(notes)
            }
            // Create order first
            try await supabase
                .from("orders")
                .insert(order)
                .execute()
            
            // Create order items if any
            if let items = order.orderItems, !items.isEmpty {
                let itemsWithOrderId = items.map { item -> OrderItem in
                    // Note: OrderItem is a struct, so we need to create new instances
                    return OrderItem(
                        id: item.id,
                        orderId: order.id,
                        itemId: item.itemId,
                        description: item.description,
                        quantity: item.quantity,
                        unitPrice: item.unitPrice,
                        totalPrice: item.totalPrice,
                        createdAt: item.createdAt
                    )
                }
                
                try await supabase
                    .from("order_items")
                    .insert(itemsWithOrderId)
                    .execute()
            }
            
            await loadFinancialData()
            updateAlerts()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateOrder(_ order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Update order
            try await supabase
                .from("orders")
                .update(order)
                .eq("id", value: order.id)
                .execute()
            
            // Delete existing order items
            try await supabase
                .from("order_items")
                .delete()
                .eq("order_id", value: order.id)
                .execute()
            
            // Insert updated order items
            if let items = order.orderItems, !items.isEmpty {
                let itemsWithOrderId = items.map { item -> OrderItem in
                    OrderItem(
                        id: item.id,
                        orderId: order.id,
                        itemId: item.itemId,
                        description: item.description,
                        quantity: item.quantity,
                        unitPrice: item.unitPrice,
                        totalPrice: item.totalPrice,
                        createdAt: item.createdAt
                    )
                }
                
                try await supabase
                    .from("order_items")
                    .insert(itemsWithOrderId)
                    .execute()
            }
            
            await loadFinancialData()
            updateAlerts()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteOrder(_ order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Order items are automatically deleted via CASCADE
            // But we can be explicit for clarity
            try await supabase
                .from("order_items")
                .delete()
                .eq("order_id", value: order.id)
                .execute()
            
            try await supabase
                .from("orders")
                .delete()
                .eq("id", value: order.id)
                .execute()
            
            await loadFinancialData()
            updateVendorPerformance()
            updateAlerts()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteOrders(_ ordersToDelete: [Order]) async throws {
        guard !ordersToDelete.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            for order in ordersToDelete {
                try await supabase
                    .from("order_items")
                    .delete()
                    .eq("order_id", value: order.id)
                    .execute()
                
                try await supabase
                    .from("orders")
                    .delete()
                    .eq("id", value: order.id)
                    .execute()
            }
            
            await loadFinancialData()
            updateVendorPerformance()
            updateAlerts()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateOrders(_ ordersToUpdate: [Order]) async throws {
        guard !ordersToUpdate.isEmpty else { return }
        for order in ordersToUpdate {
            try await updateOrder(order)
        }
    }
    
    func assignOrders(orderIds: [UUID], budgetId: UUID?, categoryId: UUID?) async throws {
        let updated = orders.compactMap { order -> Order? in
            guard orderIds.contains(order.id) else { return nil }
            var copy = order
            copy.budgetId = budgetId
            copy.budgetCategoryId = categoryId
            return copy
        }
        try await updateOrders(updated)
    }
    
    func updateOrderStatus(orderIds: [UUID], status: OrderStatus) async throws {
        let updated = orders.compactMap { order -> Order? in
            guard orderIds.contains(order.id) else { return nil }
            var copy = order
            copy.status = status
            return copy
        }
        try await updateOrders(updated)
    }
    
    // MARK: - Vendor Performance Tracking
    
    private func updateVendorPerformance() {
        // Calculate vendor statistics from orders
        for vendorIndex in vendors.indices {
            let vendorOrders = orders.filter { $0.vendor == vendors[vendorIndex].name && $0.status != .cancelled }
            
            // Update order count and total spent
            var updatedVendor = vendors[vendorIndex]
            updatedVendor.totalOrders = vendorOrders.count
            updatedVendor.totalSpent = vendorOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
            
            // Calculate average delivery days
            let deliveryDurations = vendorOrders.compactMap { order -> Double? in
                guard let expected = order.expectedDeliveryDate,
                      let actual = order.actualDeliveryDate else { return nil }
                let duration = actual.timeIntervalSince(expected) / 86400 // Convert to days
                return duration
            }
            
            if !deliveryDurations.isEmpty {
                let average = deliveryDurations.reduce(0, +) / Double(deliveryDurations.count)
                updatedVendor.averageDeliveryDays = average
            }
            
            vendors[vendorIndex] = updatedVendor
        }
    }
    
    func updateVendorRating(vendorId: UUID, rating: Int) async throws {
        guard let index = vendors.firstIndex(where: { $0.id == vendorId }) else {
            throw NSError(domain: "FinanceService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Vendor not found"])
        }
        
        var updatedVendor = vendors[index]
        updatedVendor.rating = max(1, min(5, rating)) // Clamp between 1-5
        
        try await updateVendor(updatedVendor)
    }
    
    // MARK: - Vendor Operations
    
    func createVendor(_ vendor: Vendor) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            _ = try InputValidator.VendorNameInput(vendor.name)
            try await supabase
                .from("vendors")
                .insert(vendor)
                .execute()
            await loadFinancialData()
            updateVendorPerformance()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateVendor(_ vendor: Vendor) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("vendors")
                .update(vendor)
                .eq("id", value: vendor.id)
                .execute()
            await loadFinancialData()
            updateVendorPerformance()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteVendor(_ vendor: Vendor) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("vendors")
                .delete()
                .eq("id", value: vendor.id)
                .execute()
            await loadFinancialData()
            updateVendorPerformance()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Budget Template Operations
    
    func createBudgetTemplate(_ template: BudgetTemplate) async throws {
        // Budget templates table may not exist, so catch error gracefully
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("budget_templates")
                .insert(template)
                .execute()
            await loadFinancialData()
        } catch {
            // Table doesn't exist, silently fail
            errorMessage = nil
        }
    }
    
    func updateBudgetTemplate(_ template: BudgetTemplate) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("budget_templates")
                .update(template)
                .eq("id", value: template.id)
                .execute()
            await loadFinancialData()
        } catch {
            // Table doesn't exist, silently fail
            errorMessage = nil
        }
    }
    
    func deleteBudgetTemplate(_ template: BudgetTemplate) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("budget_templates")
                .delete()
                .eq("id", value: template.id)
                .execute()
            await loadFinancialData()
        } catch {
            // Table doesn't exist, silently fail
            errorMessage = nil
        }
    }
    
    // MARK: - Analytics & Reporting
    
    func getFinancialSummary() -> FinancialSummary {
        let totalBudget = budgets.reduce(0) { $0 + $1.totalAmount }
        let totalSpent = orders.filter { $0.status != .cancelled }.reduce(0) { $0 + $1.totalAmount }
        let pendingOrders = orders.filter { $0.status == .pending || $0.status == .ordered }
        let pendingAmount = pendingOrders.reduce(0) { $0 + $1.totalAmount }
        
        return FinancialSummary(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalRemaining: totalBudget - totalSpent,
            pendingAmount: pendingAmount,
            orderCount: orders.count,
            vendorCount: vendors.count,
            budgetCount: budgets.count
        )
    }
    
    func getOrdersByStatus(_ status: OrderStatus) -> [Order] {
        orders.filter { $0.status == status }
    }
    
    func getOrdersByVendor(_ vendorName: String) -> [Order] {
        orders.filter { $0.vendor == vendorName }
    }
    
    func getRecentOrders(limit: Int = 5) -> [Order] {
        Array(orders.prefix(limit))
    }
    
    // MARK: - Analytics for Charts
    
    /// Days to use for spending trend charts: last 30 days when recent activity exists, otherwise span from earliest order (capped).
    func spendingTrendWindowDays(defaultDays: Int = 30, maxDays: Int = 365) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let activeOrders = orders.filter { $0.status != .cancelled }
        
        guard let earliest = activeOrders.map(\.orderDate).min() else {
            return defaultDays
        }
        
        let cutoff = calendar.date(byAdding: .day, value: -defaultDays, to: today) ?? today
        let hasRecentActivity = activeOrders.contains { $0.orderDate >= cutoff }
        
        if hasRecentActivity {
            return defaultDays
        }
        
        let start = calendar.startOfDay(for: earliest)
        let span = (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1
        return min(max(span, 1), maxDays)
    }
    
    func spendingTrendWindowDescription(defaultDays: Int = 30) -> String {
        let days = spendingTrendWindowDays(defaultDays: defaultDays)
        if days == defaultDays {
            return "Last \(defaultDays) days"
        }
        return "All orders (\(days) days)"
    }
    
    /// Get spending data points for trend chart
    func getSpendingTrends(days: Int? = nil) -> [SpendingDataPoint] {
        let windowDays = days ?? spendingTrendWindowDays()
        let calendar = Calendar.current
        let today = Date()
        var dataPoints: [SpendingDataPoint] = []
        
        for i in 0..<windowDays {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let daySpending = orders
                .filter { order in
                    order.orderDate >= startOfDay &&
                    order.orderDate < endOfDay &&
                    order.status != .cancelled
                }
                .reduce(Decimal(0)) { $0 + $1.totalAmount }
            
            dataPoints.append(SpendingDataPoint(
                date: date,
                value: Double(truncating: daySpending as NSDecimalNumber)
            ))
        }
        
        return dataPoints.reversed() // Oldest to newest
    }
    
    /// Running sum of daily spending over the same window as `getSpendingTrends` (oldest → newest).
    func getCumulativeSpendingTrends(days: Int? = nil) -> [SpendingDataPoint] {
        let daily = getSpendingTrends(days: days)
        var running = 0.0
        return daily.map { point in
            running += point.value
            return SpendingDataPoint(date: point.date, value: running)
        }
    }
    
    /// Snapshot for spending & budget card (activity buckets + pace series).
    func getSpendingTrendSnapshot(range: SpendingTrendRange) -> SpendingTrendSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let activeOrders = orders.filter { $0.status != .cancelled }
        
        let (rangeStart, rangeEnd): (Date, Date) = {
            switch range {
            case .week, .month, .quarter:
                let days = range == .week ? 7 : (range == .month ? 30 : 90)
                let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
                return (calendar.startOfDay(for: start), today)
            case .all:
                guard let earliest = activeOrders.map(\.orderDate).min() else {
                    let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today
                    return (calendar.startOfDay(for: start), today)
                }
                let earliestDay = calendar.startOfDay(for: earliest)
                let cappedStart = calendar.date(byAdding: .day, value: -364, to: today) ?? earliestDay
                let start = max(earliestDay, cappedStart)
                return (start, today)
            }
        }()
        
        let ordersInRange = activeOrders.filter { order in
            let day = calendar.startOfDay(for: order.orderDate)
            return day >= rangeStart && day <= rangeEnd
        }
        
        let totalSpentInRange = ordersInRange.reduce(Decimal(0)) { $0 + $1.totalAmount }
        let budgetCap = budgets.reduce(Decimal(0)) { $0 + $1.totalAmount }
        let percentUsed: Double? = budgetCap > 0
            ? Double(truncating: (totalSpentInRange / budgetCap * 100) as NSDecimalNumber)
            : nil
        
        let spanDays = (calendar.dateComponents([.day], from: rangeStart, to: rangeEnd).day ?? 0) + 1
        let activityBuckets = bucketSpending(
            from: rangeStart,
            to: rangeEnd,
            spanDays: spanDays,
            orders: ordersInRange,
            calendar: calendar
        )
        
        var running = 0.0
        let pacePoints = activityBuckets.map { bucket in
            running += bucket.value
            return BudgetPacePoint(date: bucket.date, cumulativeSpent: running)
        }
        
        return SpendingTrendSnapshot(
            range: range,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            activityBuckets: activityBuckets,
            pacePoints: pacePoints,
            budgetCap: budgetCap,
            totalSpentInRange: totalSpentInRange,
            orderCountInRange: ordersInRange.count,
            percentOfBudgetUsed: percentUsed,
            hasBudgets: !budgets.isEmpty
        )
    }
    
    private enum SpendingBucketGranularity {
        case daily, weekly, monthly
    }
    
    private func bucketGranularity(spanDays: Int) -> SpendingBucketGranularity {
        if spanDays > 180 { return .monthly }
        if spanDays > 60 { return .weekly }
        return .daily
    }
    
    private func bucketSpending(
        from rangeStart: Date,
        to rangeEnd: Date,
        spanDays: Int,
        orders: [Order],
        calendar: Calendar
    ) -> [SpendingDataPoint] {
        let granularity = bucketGranularity(spanDays: spanDays)
        
        switch granularity {
        case .daily:
            var points: [SpendingDataPoint] = []
            var current = rangeStart
            while current <= rangeEnd {
                let startOfDay = calendar.startOfDay(for: current)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? current
                let amount = orders
                    .filter { $0.orderDate >= startOfDay && $0.orderDate < endOfDay }
                    .reduce(Decimal(0)) { $0 + $1.totalAmount }
                points.append(SpendingDataPoint(
                    date: current,
                    value: Double(truncating: amount as NSDecimalNumber)
                ))
                guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                current = next
            }
            return points
            
        case .weekly:
            var points: [SpendingDataPoint] = []
            var weekStart = rangeStart
            while weekStart <= rangeEnd {
                let weekEnd = min(
                    calendar.date(byAdding: .day, value: 6, to: weekStart) ?? rangeEnd,
                    rangeEnd
                )
                let endExclusive = calendar.date(byAdding: .day, value: 1, to: weekEnd) ?? weekEnd
                let amount = orders
                    .filter { $0.orderDate >= weekStart && $0.orderDate < endExclusive }
                    .reduce(Decimal(0)) { $0 + $1.totalAmount }
                points.append(SpendingDataPoint(
                    date: weekStart,
                    value: Double(truncating: amount as NSDecimalNumber)
                ))
                guard let next = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
                weekStart = next
            }
            return points
            
        case .monthly:
            var points: [SpendingDataPoint] = []
            var components = calendar.dateComponents([.year, .month], from: rangeStart)
            components.day = 1
            var monthStart = calendar.date(from: components) ?? rangeStart
            if monthStart < rangeStart { monthStart = rangeStart }
            
            while monthStart <= rangeEnd {
                guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { break }
                let monthEnd = min(calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? rangeEnd, rangeEnd)
                let endExclusive = calendar.date(byAdding: .day, value: 1, to: monthEnd) ?? monthEnd
                let amount = orders
                    .filter { $0.orderDate >= monthStart && $0.orderDate < endExclusive }
                    .reduce(Decimal(0)) { $0 + $1.totalAmount }
                points.append(SpendingDataPoint(
                    date: monthStart,
                    value: Double(truncating: amount as NSDecimalNumber)
                ))
                monthStart = nextMonth
            }
            return points
        }
    }
    
    /// Get category spending breakdown
    func getCategorySpending() -> [CategorySpending] {
        var categoryTotals: [String: Decimal] = [:]
        
        for order in orders.filter({ $0.status != .cancelled }) {
            guard let budgetId = order.budgetId,
                  let budget = budgets.first(where: { $0.id == budgetId }),
                  let categoryId = order.budgetCategoryId,
                  let category = budget.categories.first(where: { $0.id == categoryId }) else {
                continue
            }
            
            let currentTotal = categoryTotals[category.name] ?? 0
            categoryTotals[category.name] = currentTotal + order.totalAmount
        }
        
        return categoryTotals.map { name, amount in
            CategorySpending(name: name, amount: Double(truncating: amount as NSDecimalNumber))
        }
        .sorted { $0.amount > $1.amount }
    }
    
    /// Get vendor spending breakdown
    func getVendorSpending() -> [VendorSpending] {
        let vendorStats = vendorSummaries
        
        return vendorStats.map { stat in
            VendorSpending(
                name: stat.name,
                amount: Double(truncating: stat.totalAmount as NSDecimalNumber),
                orderCount: stat.orderCount
            )
        }
    }
    
    /// Get spending forecast based on historical data
    func getSpendingForecast() -> SpendingForecast {
        let calendar = Calendar.current
        let now = Date()
        
        // Get last 6 months of data
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) else {
            return SpendingForecast(monthlyAverage: 0, projectedThisMonth: 0, projectedThisQuarter: 0, projectedThisYear: 0)
        }
        
        let recentOrders = orders.filter { order in
            order.orderDate >= sixMonthsAgo &&
            order.status != .cancelled
        }
        
        guard !recentOrders.isEmpty else {
            return SpendingForecast(monthlyAverage: 0, projectedThisMonth: 0, projectedThisQuarter: 0, projectedThisYear: 0)
        }
        
        // Calculate monthly spending
        var monthlySpending: [Decimal] = []
        let sixMonthsComponents = calendar.dateComponents([.year, .month], from: sixMonthsAgo)
        var currentMonth = calendar.date(from: sixMonthsComponents) ?? sixMonthsAgo
        
        while currentMonth <= now {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            
            let monthOrders = recentOrders.filter { order in
                order.orderDate >= currentMonth && order.orderDate < nextMonth
            }
            
            let monthTotal = monthOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
            monthlySpending.append(monthTotal)
            
            currentMonth = nextMonth
        }
        
        // Calculate average
        let average = monthlySpending.reduce(Decimal(0)) { $0 + $1 } / Decimal(monthlySpending.count)
        
        // Projections
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let dayOfMonth = calendar.component(.day, from: now)
        let remainingDays = daysInCurrentMonth - dayOfMonth
        
        // Calculate spending rate for current month
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: now)
        let currentMonthStart = calendar.date(from: currentMonthComponents) ?? now
        let currentMonthOrders = recentOrders.filter { $0.orderDate >= currentMonthStart }
        let currentMonthSpent = currentMonthOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
        let dailyRate = dayOfMonth > 0 ? currentMonthSpent / Decimal(dayOfMonth) : average / Decimal(30)
        let projectedThisMonth = currentMonthSpent + (dailyRate * Decimal(remainingDays))
        
        return SpendingForecast(
            monthlyAverage: Double(truncating: average as NSDecimalNumber),
            projectedThisMonth: Double(truncating: projectedThisMonth as NSDecimalNumber),
            projectedThisQuarter: Double(truncating: average * 3 as NSDecimalNumber),
            projectedThisYear: Double(truncating: average * 12 as NSDecimalNumber)
        )
    }
}

// MARK: - Forecast Model

struct SpendingForecast {
    let monthlyAverage: Double
    let projectedThisMonth: Double
    let projectedThisQuarter: Double
    let projectedThisYear: Double
}

// MARK: - Supporting Types

struct FinancialSummary {
    let totalBudget: Decimal
    let totalSpent: Decimal
    let totalRemaining: Decimal
    let pendingAmount: Decimal
    let orderCount: Int
    let vendorCount: Int
    let budgetCount: Int
    
    var percentageUsed: Double {
        guard totalBudget > 0 else { return 0 }
        return Double(truncating: (totalSpent / totalBudget) as NSNumber) * 100
    }
    
    var isOverBudget: Bool {
        totalSpent > totalBudget
    }
}

extension FinanceService {
    var budgetSummary: BudgetSummary? {
        guard !budgets.isEmpty else { return nil }
        let totalBudget = budgets.reduce(Decimal(0)) { $0 + $1.totalAmount }
        let totalSpent = calculateActualSpendingFromOrders()
        let totalRemaining = totalBudget - totalSpent
        let percentageUsed: Double = totalBudget > 0 ? Double(truncating: (totalSpent / totalBudget) as NSNumber) * 100 : 0
        let categoryCount = budgets.reduce(0) { $0 + $1.categories.count }
        let overBudgetCategories = budgets.reduce(0) { $0 + $1.categories.filter { $0.isOverBudget }.count }
        return BudgetSummary(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalRemaining: totalRemaining,
            percentageUsed: percentageUsed,
            categoryCount: categoryCount,
            overBudgetCategories: overBudgetCategories
        )
    }
    
    // MARK: - Budget-Order Linking Calculations
    
    /// Calculate actual spending from linked orders for all budgets
    func calculateActualSpendingFromOrders() -> Decimal {
        let validOrders = orders.filter { $0.status != .cancelled && $0.budgetId != nil }
        return validOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
    }
    
    /// Calculate spending for a specific budget from linked orders
    func calculateBudgetSpending(budgetId: UUID) -> Decimal {
        let budgetOrders = orders.filter { $0.budgetId == budgetId && $0.status != .cancelled }
        return budgetOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
    }
    
    /// Calculate spending for a specific budget category from linked orders
    func calculateCategorySpending(budgetId: UUID, categoryId: UUID) -> Decimal {
        let categoryOrders = orders.filter { 
            $0.budgetId == budgetId && 
            $0.budgetCategoryId == categoryId && 
            $0.status != .cancelled 
        }
        return categoryOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
    }
    
    /// Get orders linked to a specific budget
    func getOrdersForBudget(_ budgetId: UUID) -> [Order] {
        orders.filter { $0.budgetId == budgetId }
    }
    
    /// Get orders linked to a specific budget category
    func getOrdersForCategory(budgetId: UUID, categoryId: UUID) -> [Order] {
        orders.filter { 
            $0.budgetId == budgetId && 
            $0.budgetCategoryId == categoryId 
        }
    }
    
    /// Update budget category spending from linked orders
    func updateBudgetCategorySpending() {
        // This would update the budget categories' spent amounts based on linked orders
        // Note: This is a placeholder - actual implementation would need to update the database
        for budget in budgets {
            for category in budget.categories {
                let _ = calculateCategorySpending(budgetId: budget.id, categoryId: category.id)
                // In a real implementation, you would update the budget's categories array
                // and then save the budget back to the database
            }
        }
    }
    
    var pendingOrdersCount: Int {
        orders.filter { $0.status == .pending || $0.status == .ordered }.count
    }
    
    var totalSpendThisSeason: Decimal {
        orders.filter { $0.status != .cancelled }.reduce(Decimal(0)) { $0 + $1.totalAmount }
    }
    
    var averageOrderValue: Decimal {
        let validOrders = orders.filter { $0.status != .cancelled }
        guard !validOrders.isEmpty else { return 0 }
        let total = validOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
        return total / Decimal(validOrders.count)
    }
    
    var overBudgetCategories: Int {
        budgets.reduce(0) { partial, budget in
            partial + budget.categories.filter { $0.isOverBudget }.count
        }
    }
    
    var vendorSummaries: [VendorStat] {
        let grouped = Dictionary(grouping: orders.filter { $0.status != .cancelled }) { $0.vendor ?? "Unknown Vendor" }
        return grouped.map { (name, orders) in
            VendorStat(
                name: name,
                orderCount: orders.count,
                totalAmount: orders.reduce(Decimal(0)) { $0 + $1.totalAmount }
            )
        }
        .sorted { lhs, rhs in
            if lhs.orderCount == rhs.orderCount {
                return lhs.totalAmount > rhs.totalAmount
            }
            return lhs.orderCount > rhs.orderCount
        }
    }
}

struct VendorStat: Identifiable {
    let id = UUID()
    let name: String
    let orderCount: Int
    let totalAmount: Decimal
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: totalAmount as NSDecimalNumber) ?? "$0.00"
    }
}

