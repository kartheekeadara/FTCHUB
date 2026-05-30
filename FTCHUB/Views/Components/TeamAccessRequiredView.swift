//
//  TeamAccessRequiredView.swift
//  FTCHUB
//
//  Created by GPT-5 Codex on 11/8/25.
//

import SwiftUI

struct TeamAccessRequiredView: View {
    @EnvironmentObject var authService: AuthService
    let featureName: String
    var message: String?
    @State private var showingSignIn = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: authService.isGuestMode ? "person.circle" : "person.3.sequence")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Gradients.primary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(authService.isGuestMode ? "Sign In Required" : "Team Required")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(authService.isGuestMode ? 
                     "Sign in to access \(featureName). This feature requires a team account." :
                     (message ?? "Join or create a team to access \(featureName). Your data will stay organized for the right group once you're connected."))
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
                        
            if authService.isGuestMode {
                Button(action: {
                    showingSignIn = true
                }) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.md)
            } else {
            Text("Tip: Open the Team tab to create or join your group, then return to \(featureName).")
                .font(.footnote)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.background)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(authService.isGuestMode ? "Sign in required to access \(featureName)." : "Team access required. Join or create a team before using \(featureName).")
        .sheet(isPresented: $showingSignIn) {
            AuthenticationView()
                .environmentObject(authService)
        }
    }
}

#if DEBUG
struct TeamAccessRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TeamAccessRequiredView(featureName: "Inventory")
        }
    }
}
#endif

