//
//  VendorsListView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct VendorsListView: View {
    @EnvironmentObject var financeService: FinanceService
    @State private var searchText = ""
    @State private var selectedVendor: Vendor? = nil
    
    var filteredVendors: [Vendor] {
        if searchText.isEmpty {
            return financeService.vendors
        }
        return financeService.vendors.filter { vendor in
            vendor.name.lowercased().contains(searchText.lowercased()) ||
            vendor.contactPerson?.lowercased().contains(searchText.lowercased()) == true
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape: Grid layout
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                    ], spacing: DesignSystem.Spacing.md) {
                        ForEach(filteredVendors) { vendor in
                            Button(action: {
                                selectedVendor = vendor
                            }) {
                                VendorCardView(vendor: vendor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                }
            } else {
                // Portrait: List layout
                List {
                    if filteredVendors.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No vendors found")
                            .font(.headline)
                        Text("Add vendors to track your suppliers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(filteredVendors) { vendor in
                    Button(action: {
                        selectedVendor = vendor
                    }) {
                        VendorListRow(vendor: vendor)
                    }
                    .buttonStyle(.plain)
                }
                }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search vendors...")
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailView(vendor: vendor)
                .environmentObject(financeService)
        }
    }
}

// MARK: - Vendor Card View (for landscape grid)
struct VendorCardView: View {
    let vendor: Vendor
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Text(String(vendor.name.prefix(1)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if vendor.hasRating, let rating = vendor.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(star <= rating ? DesignSystem.Colors.warning : DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
            
            Text(vendor.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let contactPerson = vendor.contactPerson {
                Text(contactPerson)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            if let email = vendor.email {
                Text(email)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Vendor List Row
struct VendorListRow: View {
    let vendor: Vendor
    
    var body: some View {
        HStack(spacing: 12) {
            // Vendor Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text(String(vendor.name.prefix(1)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Vendor Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vendor.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Rating
                    if vendor.hasRating, let rating = vendor.rating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(star <= rating ? DesignSystem.Colors.warning : DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                }
                
                if let contactPerson = vendor.contactPerson {
                    Text(contactPerson)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    if let phone = vendor.phone {
                        Label(phone, systemImage: "phone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let email = vendor.email {
                        Label(email, systemImage: "envelope")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Performance metrics
                HStack(spacing: 12) {
                    if vendor.totalOrders > 0 {
                        Label("\(vendor.totalOrders) orders", systemImage: "cart")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if vendor.totalSpent > 0 {
                        Label(vendor.formattedTotalSpent, systemImage: "dollarsign.circle")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if vendor.averageDeliveryDays != nil {
                        Label(vendor.averageDeliveryText, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        VendorsListView()
            .environmentObject(FinanceService.shared)
    }
}

