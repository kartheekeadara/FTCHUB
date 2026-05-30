//
//  VendorDetailView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct VendorDetailView: View {
    let vendor: Vendor
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    
    @State private var showingRatingPicker = false
    @State private var selectedRating: Int = 3
    
    var vendorOrders: [Order] {
        financeService.orders.filter { $0.vendor == vendor.name }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    if geometry.size.width > geometry.size.height {
                        // Landscape: Two-column layout
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                ratingSection
                                performanceMetricsSection
                                contactInfoSection
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                if !vendorOrders.isEmpty {
                                    orderHistorySection
                                }
                                if let notes = vendor.notes, !notes.isEmpty {
                                    notesSection
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(DesignSystem.Spacing.md)
                    } else {
                        // Portrait: Single column
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            ratingSection
                            performanceMetricsSection
                            contactInfoSection
                            if !vendorOrders.isEmpty {
                                orderHistorySection
                            }
                            if let notes = vendor.notes, !notes.isEmpty {
                                notesSection
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(vendor.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingRatingPicker) {
                RatingPickerView(
                    currentRating: vendor.rating ?? 3,
                    onRatingSelected: { rating in
                        Task {
                            do {
                                try await financeService.updateVendorRating(vendorId: vendor.id, rating: rating)
                            } catch {
                                DebugLog.log("Error updating rating: \(error)")
                            }
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Landscape Layout Sections
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Rating")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if vendor.hasRating, let rating = vendor.rating {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(star <= rating ? DesignSystem.Colors.warning : DesignSystem.Colors.textSecondary)
                        }
                    }
                } else {
                    Text("No rating")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Button(action: { showingRatingPicker = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                MetricCard(
                    title: "Total Orders",
                    value: "\(vendorOrders.count)",
                    icon: "cart.fill",
                    color: DesignSystem.Colors.primary
                )
                
                MetricCard(
                    title: "Total Spent",
                    value: vendor.formattedTotalSpent,
                    icon: "dollarsign.circle.fill",
                    color: DesignSystem.Colors.success
                )
                
                if vendor.averageDeliveryDays != nil {
                    MetricCard(
                        title: "Avg Delivery",
                        value: vendor.averageDeliveryText,
                        icon: "clock.fill",
                        color: DesignSystem.Colors.accent
                    )
                }
                
                if vendorOrders.count > 0 {
                    let avgOrderValue = vendor.totalSpent / Decimal(vendorOrders.count)
                    MetricCard(
                        title: "Avg Order Value",
                        value: "$\(avgOrderValue.formatted())",
                        icon: "chart.bar.fill",
                        color: DesignSystem.Colors.secondary
                    )
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let contactPerson = vendor.contactPerson {
                OrderInfoRow(label: "Contact Person", value: contactPerson)
            }
            
            if let email = vendor.email {
                HStack {
                    Text("Email:")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Link(email, destination: URL(string: "mailto:\(email)")!)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            if let phone = vendor.phone {
                HStack {
                    Text("Phone:")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Link(phone, destination: URL(string: "tel:\(phone)")!)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            if let website = vendor.website {
                HStack {
                    Text("Website:")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Link(website, destination: URL(string: website)!)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            if let address = vendor.address {
                OrderInfoRow(label: "Address", value: address)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private var orderHistorySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Order History (\(vendorOrders.count))")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(vendorOrders.prefix(5)) { order in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let orderNumber = order.orderNumber {
                            Text(orderNumber)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        Text(order.orderDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(order.totalAmount.formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(order.status.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.fromString(order.status.color).opacity(0.2))
                            .foregroundColor(Color.fromString(order.status.color))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
                
                if order.id != vendorOrders.prefix(5).last?.id {
                    Divider()
                        .background(DesignSystem.Colors.border)
                }
            }
            
            if vendorOrders.count > 5 {
                Text("And \(vendorOrders.count - 5) more orders...")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.top, DesignSystem.Spacing.xs)
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
            if let notes = vendor.notes {
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

struct RatingPickerView: View {
    let currentRating: Int
    let onRatingSelected: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedRating: Int
    
    init(currentRating: Int, onRatingSelected: @escaping (Int) -> Void) {
        self.currentRating = currentRating
        self.onRatingSelected = onRatingSelected
        _selectedRating = State(initialValue: currentRating)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("Rate this vendor")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: { selectedRating = star }) {
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                    }
                }
                
                Text("\(selectedRating) out of 5")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.xl)
            .navigationTitle("Vendor Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onRatingSelected(selectedRating)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VendorDetailView(
        vendor: Vendor(
            teamId: UUID(),
            name: "Sample Vendor",
            contactPerson: "John Doe",
            email: "john@example.com",
            phone: "(555) 123-4567",
            website: "https://example.com",
            address: "123 Main St",
            notes: "Sample vendor for preview",
            rating: 4,
            averageDeliveryDays: 3.5,
            totalOrders: 10,
            totalSpent: 5000.00
        )
    )
    .environmentObject(FinanceService.shared)
}

