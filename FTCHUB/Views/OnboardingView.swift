//
//  OnboardingView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("ftchub.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    let pages: [OnboardingPageData] = [
        OnboardingPageData(
            icon: "person.3.fill",
            title: "Welcome to FTC HUB",
            description: "Your home base for FIRST Tech Challenge — the same program where teams prototype mechanisms, tune autonomous routines, and bring gracious professionalism to every match. Track your team, finances, and scouting in one place.",
            gradient: DesignSystem.Gradients.primary
        ),
        OnboardingPageData(
            icon: "chart.bar.fill",
            title: "Track Team Performance",
            description: "Monitor your team's progress with comprehensive analytics, scouting reports, and performance metrics. Make data-driven decisions to improve your game.",
            gradient: DesignSystem.Gradients.secondary
        ),
        OnboardingPageData(
            icon: "dollarsign.circle.fill",
            title: "Manage Finances",
            description: "Keep track of budgets, orders, and expenses. Stay on top of your team's financial health with detailed reporting and alerts.",
            gradient: LinearGradient(
                colors: [DesignSystem.Colors.accent, DesignSystem.Colors.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPageData(
            icon: "trophy.fill",
            title: "Competition Ready",
            description: "Access match schedules, timers, scoring calculators, and rules references. Everything you need to succeed on competition day.",
            gradient: DesignSystem.Gradients.primary
        ),
        OnboardingPageData(
            icon: "gearshape.fill",
            title: "Get Started",
            description: "Create or join a team to unlock all features. Customize your experience with settings, notifications, and preferences.",
            gradient: DesignSystem.Gradients.secondary
        )
    ]
    
    var body: some View {
        ZStack {
            AuthLightTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            DesignSystem.Haptics.impact(.light)
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundColor(AuthLightTheme.textSecondary)
                        .padding()
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Navigation buttons
                HStack(spacing: DesignSystem.Spacing.md) {
                    if currentPage > 0 {
                        Button(action: {
                            DesignSystem.Haptics.selection()
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.secondaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            DesignSystem.Haptics.selection()
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            DesignSystem.Haptics.impact(.medium)
                            completeOnboarding()
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            if currentPage < pages.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Gradients.primary)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

struct OnboardingPageData {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
}

struct OnboardingPageView: View {
    let page: OnboardingPageData
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.gradient)
                    .frame(width: 140, height: 140)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.bottom, DesignSystem.Spacing.lg)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AuthLightTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(AuthLightTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

#Preview {
    OnboardingView()
}

