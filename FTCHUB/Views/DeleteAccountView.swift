//
//  DeleteAccountView.swift
//  FTCHUB
//
//  Created for App Store Compliance - Account Deletion
//

import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showingFinalConfirmation = false
    
    private let requiredConfirmationText = "DELETE"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Warning Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.error)
                        .padding(.top, DesignSystem.Spacing.xl)
                    
                    // Title
                    Text("Delete Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    // Warning Message
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("This action cannot be undone. Deleting your account will:")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Label("Permanently delete your profile and all personal data", systemImage: "trash")
                            Label("Remove you from all teams", systemImage: "person.2.slash")
                            Label("Delete all your scouting reports, inventory entries, and other data", systemImage: "doc.text")
                            Label("Cancel all pending tasks and events", systemImage: "calendar.badge.exclamationmark")
                        }
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        // Critical warning about email reuse
                        Divider()
                            .padding(.vertical, DesignSystem.Spacing.sm)
                        
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignSystem.Colors.error)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("IMPORTANT:")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.error)
                                
                                (Text("Once you delete your account, you will ") +
                                 Text("NOT be able to sign up again with the same email address.")
                                    .fontWeight(.bold))
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.error)
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.error.opacity(0.15))
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.error.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    
                    // Confirmation Input
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("To confirm, type \"\(requiredConfirmationText)\" below:")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextField("Type DELETE to confirm", text: $confirmationText)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    
                    // Error Message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignSystem.Colors.error)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(DesignSystem.Colors.error.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Delete Button
                    Button(action: {
                        showingFinalConfirmation = true
                    }) {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Delete My Account")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            confirmationText == requiredConfirmationText && !isDeleting ?
                                DesignSystem.Colors.error :
                                DesignSystem.Colors.textTertiary
                        )
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .disabled(confirmationText != requiredConfirmationText || isDeleting)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Final Confirmation", isPresented: $showingFinalConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("Are you absolutely sure you want to delete your account? This action is permanent and cannot be undone.")
        }
    }
    
    private func deleteAccount() async {
        isDeleting = true
        errorMessage = nil
        
        do {
            try await authService.deleteAccount()
            // Account deleted successfully - user will be signed out
            // The app will navigate back to authentication view automatically
            // Dismiss the view since user is signed out
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isDeleting = false
            }
        }
    }
}

#Preview {
    DeleteAccountView()
        .environmentObject(AuthService())
}

