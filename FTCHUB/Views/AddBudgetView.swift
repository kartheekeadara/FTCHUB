//
//  AddBudgetView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct AddBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    @EnvironmentObject var teamService: TeamService
    
    @State private var name = ""
    @State private var description = ""
    @State private var totalAmount = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var categories: [BudgetCategoryInput] = []
    @State private var showingAddCategory = false
    @State private var showingStartDatePicker = false
    @State private var showingEndDatePicker = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Project/Team header
                    if let team = teamService.currentTeam {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(team.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text("Team Budget")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Budget name
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Budget name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("Enter budget name", text: $name)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Total amount
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Total amount")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("0.00", text: $totalAmount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Budget period")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            // Start date
                            Button {
                                showingStartDatePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                    Text(startDateString)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(DesignSystem.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            
                            // End date
                            Button {
                                showingEndDatePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                    Text(endDateString)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(DesignSystem.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .sheet(isPresented: $showingStartDatePicker) {
                        DatePickerSheet(selectedDate: $startDate)
                            .presentationDetents([.height(300)])
                    }
                    .sheet(isPresented: $showingEndDatePicker) {
                        DatePickerSheet(selectedDate: $endDate)
                            .presentationDetents([.height(300)])
                    }
                    
                    // Categories
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("Categories")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Button {
                                showingAddCategory = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12))
                                    Text("Add")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        
                        if categories.isEmpty {
                            Text("No categories yet")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                .padding(DesignSystem.Spacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        } else {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(categories.indices, id: \.self) { index in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(categories[index].name)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                            
                                            Text("$\(categories[index].allocated.formatted())")
                                                .font(.system(size: 14))
                                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            categories.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                        }
                                    }
                                    .padding(DesignSystem.Spacing.md)
                                    .background(DesignSystem.Colors.tertiaryBackground)
                                    .cornerRadius(DesignSystem.CornerRadius.md)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Description
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Description")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Add a description...")
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $description)
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Create button
                    Button {
                        Task {
                            await createBudget()
                        }
                    } label: {
                        Text("Add budget")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Gradients.primary)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(name.isEmpty || totalAmount.isEmpty || !isValidAmount || isCreating)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Add new budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(categories: $categories)
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var startDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: startDate)
    }
    
    private var endDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: endDate)
    }
    
    private var isValidAmount: Bool {
        guard let amount = Decimal(string: totalAmount), amount > 0 else {
            return false
        }
        return true
    }
    
    private func createBudget() async {
        guard let teamId = teamService.currentTeam?.id else {
            errorMessage = "You must be part of a team to create a budget"
            return
        }
        
        guard let totalAmountDecimal = Decimal(string: totalAmount), totalAmountDecimal > 0 else {
            errorMessage = "Please enter a valid budget amount"
            return
        }
        
        // Validate category allocations don't exceed total
        let categoryTotal = categories.reduce(Decimal(0)) { $0 + $1.allocated }
        if categoryTotal > totalAmountDecimal {
            errorMessage = "Category allocations ($\(categoryTotal.formatted())) exceed total budget ($\(totalAmountDecimal.formatted()))"
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        do {
            let budgetCategories = categories.map { input in
                BudgetCategory(
                    name: input.name,
                    allocated: input.allocated,
                    spent: 0
                )
            }
            
            let budget = Budget(
                id: UUID(),
                teamId: teamId,
                name: name,
                description: description.isEmpty ? nil : description,
                totalAmount: totalAmountDecimal,
                startDate: startDate,
                endDate: endDate,
                categories: budgetCategories,
                createdBy: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await financeService.createBudget(budget)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                // Provide user-friendly error messages
                let errorMsg = error.localizedDescription
                if errorMsg.contains("violates") || errorMsg.contains("constraint") {
                    errorMessage = "Invalid budget data. Please check all fields and try again."
                } else if errorMsg.contains("network") || errorMsg.contains("connection") {
                    errorMessage = "Network error. Please check your connection and try again."
                } else {
                    errorMessage = "Failed to create budget: \(errorMsg)"
                }
                isCreating = false
            }
        }
    }
}

struct BudgetCategoryInput: Identifiable {
    let id = UUID()
    var name: String
    var allocated: Decimal
}

struct AddCategoryView: View {
    @Binding var categories: [BudgetCategoryInput]
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Category name
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Category name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("Enter category name", text: $name)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
                    
                    // Allocated amount
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Allocated amount")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Add button
                    Button {
                        addCategory()
                    } label: {
                        Text("Add category")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Gradients.primary)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(name.isEmpty || amount.isEmpty || Decimal(string: amount) == nil)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func addCategory() {
        guard let allocated = Decimal(string: amount), allocated > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        categories.append(BudgetCategoryInput(name: name, allocated: allocated))
        dismiss()
    }
}

// MARK: - Date Picker Sheet (reused from EventEditorView)
private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// Keep BudgetDetailView and CategoryProgressRow as they are
struct BudgetDetailView: View {
    let budget: Budget
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    
    var actualSpending: Decimal {
        financeService.calculateBudgetSpending(budgetId: budget.id)
    }
    
    var linkedOrders: [Order] {
        financeService.getOrdersForBudget(budget.id)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    if geometry.size.width > geometry.size.height {
                        // Landscape: Two-column layout
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                budgetOverviewSection
                                spendingSummarySection
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                categoriesSection
                                if !linkedOrders.isEmpty {
                                    linkedOrdersSection
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(DesignSystem.Spacing.md)
                    } else {
                        // Portrait: Single column
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            budgetOverviewSection
                            spendingSummarySection
                            categoriesSection
                            if !linkedOrders.isEmpty {
                                linkedOrdersSection
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
                .refreshable {
                    await financeService.loadFinancialData()
                }
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(budget.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Landscape Layout Sections
    private var budgetOverviewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Budget Overview")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let description = budget.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            HStack {
                Text("Period:")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
                Text("\(budget.startDate.formatted(date: .abbreviated, time: .omitted)) - \(budget.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private var spendingSummarySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Spending Summary")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("$\(budget.totalAmount.formatted())")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Actual")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("$\(actualSpending.formatted())")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(budget.isOverBudget ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                }
            }
            
            ProgressView(value: budget.percentageUsed, total: 100)
                .progressViewStyle(.linear)
                .tint(budget.isOverBudget ? DesignSystem.Colors.error : DesignSystem.Colors.primary)
            
            HStack {
                Text("\(String(format: "%.1f", budget.percentageUsed))% Used")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if budget.remainingAmount > 0 {
                    Text("$\(budget.remainingAmount.formatted()) remaining")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.success)
                } else {
                    Text("$\(abs(budget.remainingAmount).formatted()) over")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Categories (\(budget.categories.count))")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(budget.categories) { category in
                CategoryProgressRow(category: category, budgetId: budget.id, financeService: financeService)
                
                if category.id != budget.categories.last?.id {
                    Divider()
                        .background(DesignSystem.Colors.border)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private var linkedOrdersSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Linked Orders (\(linkedOrders.count))")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(linkedOrders.prefix(5)) { order in
                HStack {
                    Text(order.vendorName)
                        .font(.subheadline)
                    Spacer()
                    Text("$\(order.totalAmount.formatted())")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if order.id != linkedOrders.prefix(5).last?.id {
                    Divider()
                        .background(DesignSystem.Colors.border)
                }
            }
            
            if linkedOrders.count > 5 {
                Text("And \(linkedOrders.count - 5) more orders...")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct CategoryProgressRow: View {
    let category: BudgetCategory
    let budgetId: UUID
    let financeService: FinanceService
    
    var categorySpending: Decimal {
        financeService.calculateCategorySpending(budgetId: budgetId, categoryId: category.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if category.isOverBudget {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            
            HStack {
                Text("Allocated: $\(category.allocated.formatted())")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text("Spent: $\(categorySpending.formatted())")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(category.isOverBudget ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary)
            }
            
            ProgressView(value: category.percentageUsed, total: 100)
                .progressViewStyle(.linear)
                .tint(category.isOverBudget ? DesignSystem.Colors.error : DesignSystem.Colors.primary)
                .frame(height: 6)
        }
    }
}

#Preview {
    AddBudgetView()
        .environmentObject(FinanceService.shared)
        .environmentObject(TeamService())
}
