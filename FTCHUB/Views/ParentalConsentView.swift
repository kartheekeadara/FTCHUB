//
//  ParentalConsentView.swift
//  FTCHUB
//
//  Created for COPPA Compliance
//

import SwiftUI

struct ParentalConsentView: View {
    @EnvironmentObject var consentService: ConsentService
    @Environment(\.dismiss) private var dismiss
    
    let userId: UUID
    let childName: String
    let childEmail: String
    
    @State private var parentName = ""
    @State private var parentEmail = ""
    @State private var parentPhone = ""
    @State private var relationship = "parent"
    @State private var hasReadPrivacyPolicy = false
    @State private var hasReadTerms = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    
    private let relationships = ["parent", "guardian", "legal_guardian", "other"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "person.2.badge.shield.checkmark.fill")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Text("Parental Consent Required")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("COPPA Compliance")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, DesignSystem.Spacing.xl)
                    
                    // Information Box
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Why we need your consent:")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Label("Your child is under 13 years old", systemImage: "checkmark.circle")
                            Label("Federal law (COPPA) requires parental consent", systemImage: "checkmark.circle")
                            Label("We collect minimal data for team management", systemImage: "checkmark.circle")
                            Label("You can revoke consent at any time", systemImage: "checkmark.circle")
                        }
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Child Information
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Child Information")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Name: \(childName)")
                            Text("Email: \(childEmail)")
                        }
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Parent/Guardian Information Form
                    VStack(spacing: DesignSystem.Spacing.md) {
                        CustomTextField(
                            title: "Your Name (Parent/Guardian)",
                            text: $parentName,
                            placeholder: "Enter your full name"
                        )
                        
                        CustomTextField(
                            title: "Your Email",
                            text: $parentEmail,
                            placeholder: "parent@example.com"
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        
                        CustomTextField(
                            title: "Your Phone Number",
                            text: $parentPhone,
                            placeholder: "(555) 123-4567"
                        )
                        .keyboardType(.phonePad)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Relationship to Child")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Picker("Relationship", selection: $relationship) {
                                ForEach(relationships, id: \.self) { rel in
                                    Text(rel.capitalized).tag(rel)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Consent Checkboxes
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("I confirm that:")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Button(action: {
                                hasReadPrivacyPolicy.toggle()
                            }) {
                                Image(systemName: hasReadPrivacyPolicy ? "checkmark.square.fill" : "square")
                                    .foregroundColor(hasReadPrivacyPolicy ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                            }
                            
                            HStack(spacing: 4) {
                                Text("I have read and agree to the")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Button("Privacy Policy") {
                                    showingPrivacyPolicy = true
                                }
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Button(action: {
                                hasReadTerms.toggle()
                            }) {
                                Image(systemName: hasReadTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(hasReadTerms ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                            }
                            
                            HStack(spacing: 4) {
                                Text("I have read and agree to the")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Button("Terms of Service") {
                                    showingTerms = true
                                }
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "checkmark.square.fill")
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Text("I consent to the collection and use of my child's information as described in the Privacy Policy for the purpose of team management and competition coordination.")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Error/Success Messages
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    if let success = successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.success)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Submit Button
                    Button(action: submitConsent) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Submit Consent")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            isFormValid && !isSubmitting ?
                                DesignSystem.Gradients.primary :
                                LinearGradient(colors: [DesignSystem.Colors.textTertiary], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Parental Consent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationStack {
                LegalDocumentView(title: "Privacy Policy", resourceName: "PrivacyPolicy", showDismissToolbar: true)
            }
        }
        .sheet(isPresented: $showingTerms) {
            NavigationStack {
                LegalDocumentView(title: "Terms of Service", resourceName: "TermsOfService", showDismissToolbar: true)
            }
        }
    }
    
    private var isFormValid: Bool {
        !parentName.isEmpty &&
        !parentEmail.isEmpty &&
        SecurityUtils.validateEmail(parentEmail) &&
        hasReadPrivacyPolicy &&
        hasReadTerms
    }
    
    private func submitConsent() {
        guard isFormValid else { return }
        
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                _ = try await consentService.createConsentRecord(
                    userId: userId,
                    parentName: parentName,
                    parentEmail: parentEmail,
                    parentPhone: parentPhone.isEmpty ? nil : parentPhone,
                    relationship: relationship,
                    consentType: .coppa,
                    verificationMethod: .email
                )
                
                successMessage = "Consent submitted successfully. A verification email has been sent to \(parentEmail). Please check your email to complete verification."
                
                // Dismiss after a delay
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

#Preview {
    ParentalConsentView(
        userId: UUID(),
        childName: "John Doe",
        childEmail: "john@example.com"
    )
    .environmentObject(ConsentService.shared)
}

