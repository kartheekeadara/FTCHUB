//
//  ReportContentView.swift
//  FTCHUB
//
//  Created for App Store Compliance - Content Moderation
//

import SwiftUI

struct ReportContentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var moderationService: ContentModerationService
    
    let contentType: ContentReport.ContentType
    let contentId: UUID
    let contentTitle: String
    
    @State private var selectedReason: ContentReport.ReportReason = .inappropriate
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Report: \(contentTitle)")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                } header: {
                    Text("Content")
                }
                
                Section {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(ContentReport.ReportReason.allCases, id: \.self) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                } header: {
                    Text("Reason for Reporting")
                } footer: {
                    Text("Please select the reason that best describes why you're reporting this content.")
                }
                
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                } header: {
                    Text("Additional Details (Optional)")
                } footer: {
                    Text("Provide any additional information that may help us review this report.")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(DesignSystem.Colors.error)
                            .font(.caption)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(DesignSystem.Colors.success)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
    
    private func submitReport() {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await moderationService.reportContent(
                    contentType: contentType,
                    contentId: contentId,
                    reason: selectedReason,
                    description: description.isEmpty ? nil : description
                )
                
                successMessage = "Report submitted successfully. Our team will review it shortly."
                
                // Dismiss after a delay
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

#Preview {
    ReportContentView(
        contentType: .scoutingReport,
        contentId: UUID(),
        contentTitle: "Scouting Report #12345"
    )
    .environmentObject(ContentModerationService.shared)
}

