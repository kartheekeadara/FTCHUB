//
//  InviteCodeView.swift
//  FTCHUB
//
//  Created for Team Invitation Management
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct InviteCodeView: View {
    @EnvironmentObject var teamService: TeamService
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRegenerating = false
    @State private var showingRegenerateConfirmation = false
    @State private var showingShareSheet = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var copiedToClipboard = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(DesignSystem.Gradients.primary)
                    
                    Text("Team Invite Code")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Share this code with people you want to invite to your team")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(.top, DesignSystem.Spacing.xl)
                
                // Invite Code Card
                if let inviteCode = teamService.currentInviteCode {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Code Display
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Invite Code")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text(inviteCode)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(DesignSystem.Spacing.lg)
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                        .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Action Buttons
                        VStack(spacing: DesignSystem.Spacing.md) {
                            // Copy Button
                            Button {
                                copyToClipboard(code: inviteCode)
                            } label: {
                                HStack {
                                    Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                    Text(copiedToClipboard ? "Copied!" : "Copy Code")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(copiedToClipboard ? DesignSystem.Colors.success : DesignSystem.Colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            
                            // Share Button
                            Button {
                                shareCode(code: inviteCode)
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill")
                                    Text("Share Code")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.Colors.secondary)
                                .foregroundColor(.white)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            
                            // Regenerate Button
                            Button {
                                showingRegenerateConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Generate New Code")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            .disabled(isRegenerating)
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
                } else {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.warning)
                        Text("No team found")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text("You need to be part of a team to generate invite codes")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(DesignSystem.Spacing.xl)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("How it works")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    InstructionRow(
                        number: "1",
                        text: "Share the invite code with people you want to invite"
                    )
                    
                    InstructionRow(
                        number: "2",
                        text: "They enter the code in the app to request to join"
                    )
                    
                    InstructionRow(
                        number: "3",
                        text: "You'll receive a notification to approve their request"
                    )
                }
                .padding(DesignSystem.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .navigationTitle("Invite Members")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Regenerate Invite Code?", isPresented: $showingRegenerateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Regenerate") {
                Task {
                    await regenerateCode()
                }
            }
        } message: {
            Text("Generating a new invite code will not affect existing team members. Only new people joining will need to use the new code.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let inviteCode = teamService.currentInviteCode {
                InviteCodeShareSheet(activityItems: [
                    "Join my FTC team! Use invite code: \(inviteCode)\n\nDownload FTC HUB app and enter this code to request to join."
                ])
            }
        }
    }
    
    private func copyToClipboard(code: String) {
        UIPasteboard.general.string = code
        copiedToClipboard = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedToClipboard = false
        }
    }
    
    private func shareCode(code: String) {
        showingShareSheet = true
    }
    
    private func regenerateCode() async {
        isRegenerating = true
        errorMessage = nil
        
        do {
            try await teamService.regenerateInviteCode()
            copiedToClipboard = false
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isRegenerating = false
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(DesignSystem.Colors.primary)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Share Sheet
#if canImport(UIKit)
struct InviteCodeShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

