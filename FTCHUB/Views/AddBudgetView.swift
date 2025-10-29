//
//  AddBudgetView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct AddBudgetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Budget creation coming soon")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AddVendorView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Vendor creation coming soon")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct BudgetDetailView: View {
    let budget: Budget
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Budget details coming soon")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle(budget.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct VendorDetailView: View {
    let vendor: Vendor
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Vendor details coming soon")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle(vendor.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddBudgetView()
}

