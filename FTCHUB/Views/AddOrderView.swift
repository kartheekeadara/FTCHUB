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
    @EnvironmentObject var teamService: TeamService
    
    /// Merged into notes on first appear (e.g. Season workspace wishlist export).
    var prefilledNotes: String? = nil
    /// When amount field is empty, set once from wishlist total estimate.
    var prefilledAmount: String? = nil
    
    @State private var vendor = ""
    @State private var orderNumber = ""
    @State private var amount = ""
    @State private var orderDate = Date()
    @State private var status: OrderStatus = .pending
    @State private var notes = ""
    @State private var selectedBudgetId: UUID?
    @State private var expectedDeliveryDate: Date?
    @State private var showingDatePicker = false
    @State private var showingDeliveryDatePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didApplyPrefill = false
    
    @EnvironmentObject var inventoryService: InventoryService
    
    private func statusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .ordered: return .blue
        case .received: return .green
        case .cancelled: return .red
        }
    }
    
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
                                
                                Text("Team Order")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Status selector
                            Menu {
                                ForEach(OrderStatus.allCases, id: \.self) { statusOption in
                                    Button {
                                        status = statusOption
                                    } label: {
                                        HStack {
                                            Circle()
                                                .fill(statusColor(statusOption))
                                                .frame(width: 12, height: 12)
                                            Text(statusOption.displayName)
                                            if status == statusOption {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(statusColor(status))
                                        .frame(width: 10, height: 10)
                                    Text(status.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(DesignSystem.Colors.primary.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Vendor name
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Vendor name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("Enter vendor name", text: $vendor)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Order number (optional)
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Order number (optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("Enter order number", text: $orderNumber)
                            .textInputAutocapitalization(.none)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Amount
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Cost")
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
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Timeline")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            // Order date
                            Button {
                                showingDatePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                    Text(dateString)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(DesignSystem.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            
                            // Expected delivery (optional)
                            Button {
                                showingDeliveryDatePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "shippingbox")
                                        .font(.system(size: 14))
                                    Text(expectedDeliveryString)
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
                    .sheet(isPresented: $showingDatePicker) {
                        DatePickerSheet(
                            selectedDate: $orderDate
                        )
                        .presentationDetents([.height(300)])
                    }
                    .sheet(isPresented: $showingDeliveryDatePicker) {
                        OptionalDatePickerSheet(
                            selectedDate: Binding(
                                get: { expectedDeliveryDate ?? Date() },
                                set: { expectedDeliveryDate = $0 }
                            ),
                            isEnabled: Binding(
                                get: { expectedDeliveryDate != nil },
                                set: { if $0 { expectedDeliveryDate = Date().addingTimeInterval(86400 * 7) } else { expectedDeliveryDate = nil } }
                            )
                        )
                        .presentationDetents([.height(350)])
                    }
                    
                    // Budget
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Budget (optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Menu {
                            Button {
                                selectedBudgetId = nil
                            } label: {
                                HStack {
                                    Text("None")
                                    if selectedBudgetId == nil {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            ForEach(financeService.budgets) { budget in
                                Button {
                                    selectedBudgetId = budget.id
                                } label: {
                                    HStack {
                                        Text(budget.name)
                                        if selectedBudgetId == budget.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                    .font(.system(size: 14))
                                Text(selectedBudgetName)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(DesignSystem.Spacing.md)
                            .frame(maxWidth: .infinity)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Notes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Add notes...")
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $notes)
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
                    
                    // Save button
                    Button {
                        Task {
                            await saveOrder()
                        }
                    } label: {
                        Text("Add order")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Gradients.primary)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(vendor.isEmpty || amount.isEmpty || isSaving)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Add new order")
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
            .onAppear {
                applyPrefillIfNeeded()
            }
        }
    }
    
    private func applyPrefillIfNeeded() {
        guard !didApplyPrefill else { return }
        didApplyPrefill = true
        if let note = prefilledNotes?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                notes = note
            } else {
                notes += "\n\n" + note
            }
        }
        if amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let amt = prefilledAmount?.trimmingCharacters(in: .whitespacesAndNewlines), !amt.isEmpty {
            amount = amt
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: orderDate)
    }
    
    private var expectedDeliveryString: String {
        if let date = expectedDeliveryDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        } else {
            return "Not set"
        }
    }
    
    private var selectedBudgetName: String {
        if let budgetId = selectedBudgetId,
           let budget = financeService.budgets.first(where: { $0.id == budgetId }) {
            return budget.name
        } else {
            return "None"
        }
    }
    
    private func saveOrder() async {
        guard !vendor.isEmpty else {
            errorMessage = "Vendor name is required"
            return
        }
        
        guard !amount.isEmpty, let amountValue = Decimal(string: amount) else {
            errorMessage = "Please enter a valid cost"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        let orderId = UUID()
        let teamId = financeService.activeTeamId ?? teamService.currentTeam?.id ?? UUID()
        
        let newOrder = Order(
            id: orderId,
            teamId: teamId,
            orderNumber: orderNumber.isEmpty ? nil : orderNumber,
            vendor: vendor,
            totalAmount: amountValue,
            orderDate: orderDate,
            status: status,
            notes: notes.isEmpty ? nil : notes,
            receiptUrl: nil,
            receiptUrls: nil,
            budgetId: selectedBudgetId,
            budgetCategoryId: nil,
            expectedDeliveryDate: expectedDeliveryDate,
            actualDeliveryDate: nil,
            orderItems: nil,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await financeService.createOrder(newOrder)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        isSaving = false
    }
}

// MARK: - Date Picker Sheet
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

// MARK: - Optional Date Picker Sheet
private struct OptionalDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Toggle("Set Expected Delivery Date", isOn: $isEnabled)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                
                if isEnabled {
                    DatePicker("Expected Delivery", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                }
            }
            .navigationTitle("Expected Delivery")
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

#Preview {
    AddOrderView()
        .environmentObject(FinanceService.shared)
        .environmentObject(TeamService())
        .environmentObject(InventoryService())
}
