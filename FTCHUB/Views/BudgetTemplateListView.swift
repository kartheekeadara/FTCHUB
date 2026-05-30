//
//  BudgetTemplateListView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct BudgetTemplateListView: View {
    @EnvironmentObject var financeService: FinanceService
    @State private var showingAddTemplate = false
    @State private var selectedTemplate: BudgetTemplate?
    @State private var showingUseTemplate = false
    
    var body: some View {
        NavigationView {
            List {
                if financeService.budgetTemplates.isEmpty {
                    Section {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Text("No templates found")
                                .font(.headline)
                            Text("Create budget templates to quickly set up new budgets")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.xl)
                    }
                } else {
                    ForEach(financeService.budgetTemplates) { template in
                        Button(action: {
                            selectedTemplate = template
                        }) {
                            BudgetTemplateRow(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Budget Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTemplate = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $selectedTemplate) { template in
                BudgetTemplateDetailView(template: template)
                    .environmentObject(financeService)
            }
            .sheet(isPresented: $showingAddTemplate) {
                AddBudgetTemplateView()
                    .environmentObject(financeService)
            }
        }
    }
}

struct BudgetTemplateRow: View {
    let template: BudgetTemplate
    
    var totalAmount: Decimal {
        template.categories.reduce(Decimal(0)) { $0 + $1.allocatedAmount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(template.name)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let description = template.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(template.categories.count) categories", systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text("Total: $\(totalAmount.formatted())")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct BudgetTemplateDetailView: View {
    let template: BudgetTemplate
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    @State private var showingUseTemplate = false
    
    var totalAmount: Decimal {
        template.categories.reduce(Decimal(0)) { $0 + $1.allocatedAmount }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    // Template Info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Template Information")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let description = template.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        HStack {
                            Text("Total Amount:")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text("$\(totalAmount.formatted())")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        HStack {
                            Text("Categories:")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text("\(template.categories.count)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    
                    // Categories
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Categories")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        ForEach(template.categories) { category in
                            HStack {
                                Text(category.name)
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("$\(category.allocatedAmount.formatted())")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    if let percent = category.suggestedPercent {
                                        Text("\(String(format: "%.0f", percent))%")
                                            .font(.caption2)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                }
                            }
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            
                            if category.id != template.categories.last?.id {
                                Divider()
                                    .background(DesignSystem.Colors.border)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use Template") {
                        showingUseTemplate = true
                    }
                }
            }
            .sheet(isPresented: $showingUseTemplate) {
                UseBudgetTemplateView(template: template)
                    .environmentObject(financeService)
            }
        }
    }
}

struct UseBudgetTemplateView: View {
    let template: BudgetTemplate
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    
    @State private var budgetName: String = ""
    @State private var description: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Information") {
                    TextField("Budget Name", text: $budgetName)
                    
                    TextEditor(text: $description)
                        .frame(height: 80)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("From Template") {
                    Text(template.name)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(template.categories.count) categories")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            .navigationTitle("Create from Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createBudgetFromTemplate()
                    }
                    .disabled(budgetName.isEmpty)
                }
            }
        }
        .onAppear {
            if budgetName.isEmpty {
                budgetName = template.name
            }
            if description.isEmpty {
                description = template.description ?? ""
            }
        }
    }
    
    private func createBudgetFromTemplate() {
        guard let teamId = financeService.activeTeamId ?? UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else {
            errorMessage = "Invalid team ID"
            return
        }
        
        let budget = template.toBudget(startDate: startDate, endDate: endDate, teamId: teamId)
        
        Task {
            do {
                try await financeService.createBudget(budget)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct AddBudgetTemplateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    
    @State private var templateName: String = ""
    @State private var description: String = ""
    @State private var categories: [BudgetCategoryTemplate] = []
    @State private var showingAddCategory = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Template Information") {
                    TextField("Template Name", text: $templateName)
                    TextEditor(text: $description)
                        .frame(height: 80)
                }
                
                Section("Categories") {
                    if categories.isEmpty {
                        Text("No categories yet. Add categories to define budget allocation.")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    } else {
                        ForEach(categories) { category in
                            HStack {
                                Text(category.name)
                                Spacer()
                                Text("$\(category.allocatedAmount.formatted())")
                                    .fontWeight(.medium)
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    
                    Button(action: { showingAddCategory = true }) {
                        Label("Add Category", systemImage: "plus.circle")
                    }
                }
                
                if !categories.isEmpty {
                    Section {
                        HStack {
                            Text("Total:")
                                .font(.headline)
                            Spacer()
                            Text("$\(categories.reduce(Decimal(0)) { $0 + $1.allocatedAmount }.formatted())")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(templateName.isEmpty || categories.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryTemplateView { category in
                    categories.append(category)
                }
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }
    
    private func saveTemplate() {
        guard let teamId = financeService.activeTeamId ?? UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else {
            errorMessage = "Invalid team ID"
            return
        }
        
        let template = BudgetTemplate(
            id: UUID(),
            teamId: teamId,
            name: templateName,
            description: description.isEmpty ? nil : description,
            categories: categories,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            do {
                try await financeService.createBudgetTemplate(template)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct AddCategoryTemplateView: View {
    let onSave: (BudgetCategoryTemplate) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var usePercent: Bool = false
    @State private var percent: String = ""
    @State private var totalBudget: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Information") {
                    TextField("Category Name", text: $name)
                    
                    Toggle("Use Percentage", isOn: $usePercent)
                    
                    if usePercent {
                        TextField("Percentage", text: $percent)
                            .keyboardType(.decimalPad)
                        
                        TextField("Total Budget Amount", text: $totalBudget)
                            .keyboardType(.decimalPad)
                    } else {
                        TextField("Allocated Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                if usePercent, let percentValue = Double(percent), let totalValue = Decimal(string: totalBudget) {
                    Section("Calculated") {
                        let calculatedAmount = totalValue * Decimal(percentValue) / Decimal(100)
                        Text("Amount: $\(calculatedAmount.formatted())")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty || (usePercent ? (percent.isEmpty || totalBudget.isEmpty) : amount.isEmpty))
                }
            }
        }
    }
    
    private func saveCategory() {
        let allocatedAmount: Decimal
        
        if usePercent, let percentValue = Double(percent), let totalValue = Decimal(string: totalBudget) {
            allocatedAmount = totalValue * Decimal(percentValue) / Decimal(100)
        } else {
            guard let amountValue = Decimal(string: amount) else { return }
            allocatedAmount = amountValue
        }
        
        let category = BudgetCategoryTemplate(
            name: name,
            allocatedAmount: allocatedAmount,
            suggestedPercent: usePercent ? Double(percent) : nil
        )
        
        onSave(category)
        dismiss()
    }
}

#Preview {
    BudgetTemplateListView()
        .environmentObject(FinanceService.shared)
}

