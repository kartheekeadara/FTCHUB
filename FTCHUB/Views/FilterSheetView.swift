//
//  FilterSheetView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

// MARK: - Order Filters

struct OrderFilters: Codable, Hashable {
    var statuses: Set<OrderStatus> = []
    var dateRange: DateRange? = nil
    var amountRange: AmountRange? = nil
    var vendor: String? = nil
    var budgetId: UUID? = nil
    
    var isActive: Bool {
        !statuses.isEmpty ||
        dateRange != nil ||
        amountRange != nil ||
        vendor != nil ||
        budgetId != nil
    }
    
    static var empty: OrderFilters {
        OrderFilters()
    }
}

struct DateRange: Codable, Hashable {
    var startDate: Date
    var endDate: Date
    
    func contains(_ date: Date) -> Bool {
        date >= startDate && date <= endDate
    }
}

struct AmountRange: Codable, Hashable {
    var minAmount: Decimal?
    var maxAmount: Decimal?
    
    func contains(_ amount: Decimal) -> Bool {
        let minCheck = minAmount == nil || amount >= minAmount!
        let maxCheck = maxAmount == nil || amount <= maxAmount!
        return minCheck && maxCheck
    }
}

struct FilterSheetView: View {
    @Binding var filters: OrderFilters
    let budgets: [Budget]
    let vendors: [Vendor]
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedStatuses: Set<OrderStatus> = []
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var useDateRange: Bool = false
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var useAmountRange: Bool = false
    @State private var selectedVendor: Vendor? = nil
    @State private var selectedBudget: Budget? = nil
    
    var body: some View {
        NavigationView {
            Form {
                // Status Filter
                Section("Status") {
                    ForEach(OrderStatus.allCases, id: \.self) { status in
                        Toggle(isOn: Binding(
                            get: { selectedStatuses.contains(status) },
                            set: { isOn in
                                if isOn {
                                    selectedStatuses.insert(status)
                                } else {
                                    selectedStatuses.remove(status)
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: status.icon)
                                    .foregroundColor(Color.fromString(status.color))
                                Text(status.displayName)
                            }
                        }
                    }
                }
                
                // Date Range Filter
                Section("Date Range") {
                    Toggle("Filter by Date Range", isOn: $useDateRange)
                    
                    if useDateRange {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
                
                // Amount Range Filter
                Section("Amount Range") {
                    Toggle("Filter by Amount Range", isOn: $useAmountRange)
                    
                    if useAmountRange {
                        TextField("Min Amount", text: $minAmount)
                            .keyboardType(.decimalPad)
                        
                        TextField("Max Amount", text: $maxAmount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Vendor Filter
                Section("Vendor") {
                    Picker("Vendor", selection: $selectedVendor) {
                        Text("All Vendors").tag(Vendor?.none)
                        ForEach(vendors) { vendor in
                            Text(vendor.name).tag(Vendor?.some(vendor))
                        }
                    }
                }
                
                // Budget Filter
                Section("Budget") {
                    Picker("Budget", selection: $selectedBudget) {
                        Text("All Budgets").tag(Budget?.none)
                        ForEach(budgets) { budget in
                            Text(budget.name).tag(Budget?.some(budget))
                        }
                    }
                }
            }
            .navigationTitle("Filter Orders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        clearFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentFilters()
        }
    }
    
    private func loadCurrentFilters() {
        selectedStatuses = filters.statuses
        if let dateRange = filters.dateRange {
            useDateRange = true
            startDate = dateRange.startDate
            endDate = dateRange.endDate
        }
        if let amountRange = filters.amountRange {
            useAmountRange = true
            minAmount = amountRange.minAmount.map { "\($0)" } ?? ""
            maxAmount = amountRange.maxAmount.map { "\($0)" } ?? ""
        }
        selectedVendor = vendors.first { $0.name == filters.vendor }
        selectedBudget = budgets.first { $0.id == filters.budgetId }
    }
    
    private func clearFilters() {
        selectedStatuses = []
        useDateRange = false
        useAmountRange = false
        minAmount = ""
        maxAmount = ""
        selectedVendor = nil
        selectedBudget = nil
    }
    
    private func applyFilters() {
        filters.statuses = selectedStatuses
        filters.dateRange = useDateRange ? DateRange(startDate: startDate, endDate: endDate) : nil
        filters.amountRange = useAmountRange ? AmountRange(
            minAmount: Decimal(string: minAmount),
            maxAmount: Decimal(string: maxAmount)
        ) : nil
        filters.vendor = selectedVendor?.name
        filters.budgetId = selectedBudget?.id
        dismiss()
    }
}

// MARK: - Filter Presets

struct FilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var filters: OrderFilters
    
    enum CodingKeys: String, CodingKey {
        case id, name, filters
    }
    
    init(id: UUID = UUID(), name: String, filters: OrderFilters) {
        self.id = id
        self.name = name
        self.filters = filters
    }
    
    static var defaultPresets: [FilterPreset] {
        [
            FilterPreset(name: "This Month", filters: OrderFilters(
                dateRange: DateRange(
                    startDate: Calendar.current.startOfMonth(for: Date()) ?? Date(),
                    endDate: Date()
                )
            )),
            FilterPreset(name: "Pending Orders", filters: OrderFilters(
                statuses: [.pending]
            )),
            FilterPreset(name: "Received Orders", filters: OrderFilters(
                statuses: [.received]
            )),
            FilterPreset(name: "Over $100", filters: OrderFilters(
                amountRange: AmountRange(minAmount: 100, maxAmount: nil)
            ))
        ]
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }
}

#Preview {
    FilterSheetView(
        filters: .constant(OrderFilters.empty),
        budgets: [
            Budget(
                id: UUID(),
                teamId: UUID(),
                name: "Sample Budget",
                description: nil,
                totalAmount: 10000,
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 365),
                categories: [],
                createdBy: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        vendors: [
            Vendor(
                teamId: UUID(),
                name: "Sample Vendor",
                contactPerson: nil,
                email: nil,
                phone: nil,
                website: nil,
                address: nil,
                notes: nil,
                rating: nil,
                averageDeliveryDays: nil,
                totalOrders: 0,
                totalSpent: 0
            )
        ]
    )
}

