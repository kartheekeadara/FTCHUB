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
        .searchable(text: $searchText, prompt: "Search vendors...")
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailView(vendor: vendor)
                .environmentObject(financeService)
        }
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
                Text(vendor.name)
                    .font(.headline)
                
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

