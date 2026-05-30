//
//  AddVendorView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct AddVendorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeService: FinanceService
    
    @State private var name: String = ""
    @State private var contactPerson: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var website: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Form {
                    if geometry.size.width > geometry.size.height {
                        // Landscape: Two-column layout
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                            VStack(spacing: 0) {
                                Section("Vendor Information") {
                                    TextField("Vendor Name", text: $name)
                                    TextField("Contact Person (Optional)", text: $contactPerson)
                                }
                                
                                Section("Contact Information") {
                                    TextField("Email (Optional)", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                    
                                    TextField("Phone (Optional)", text: $phone)
                                        .keyboardType(.phonePad)
                                    
                                    TextField("Website (Optional)", text: $website)
                                        .keyboardType(.URL)
                                        .autocapitalization(.none)
                                    
                                    TextField("Address (Optional)", text: $address)
                                }
                            }
                            
                            VStack(spacing: 0) {
                                Section("Notes") {
                                    TextEditor(text: $notes)
                                        .frame(height: 200)
                                }
                                
                                if let error = errorMessage {
                                    Section {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.error)
                                    }
                                }
                            }
                        }
                    } else {
                        // Portrait: Single column
                        Section("Vendor Information") {
                            TextField("Vendor Name", text: $name)
                            TextField("Contact Person (Optional)", text: $contactPerson)
                        }
                        
                        Section("Contact Information") {
                            TextField("Email (Optional)", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            TextField("Phone (Optional)", text: $phone)
                                .keyboardType(.phonePad)
                            
                            TextField("Website (Optional)", text: $website)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            
                            TextField("Address (Optional)", text: $address)
                        }
                        
                        Section("Notes") {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                        }
                        
                        if let error = errorMessage {
                            Section {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.error)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVendor()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveVendor() {
        guard let teamId = financeService.activeTeamId ?? UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else {
            errorMessage = "Invalid team ID"
            return
        }
        
        let vendor = Vendor(
            teamId: teamId,
            name: name,
            contactPerson: contactPerson.isEmpty ? nil : contactPerson,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            website: website.isEmpty ? nil : website,
            address: address.isEmpty ? nil : address,
            notes: notes.isEmpty ? nil : notes,
            rating: nil,
            averageDeliveryDays: nil,
            totalOrders: 0,
            totalSpent: 0
        )
        
        Task {
            do {
                try await financeService.createVendor(vendor)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AddVendorView()
        .environmentObject(FinanceService.shared)
}

