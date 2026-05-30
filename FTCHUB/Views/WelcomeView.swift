//
//  WelcomeView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var currentPage = 0
    @State private var timer: Timer?
    @State private var showingAuth = false
    
    let onboardingPages: [WelcomeOnboardingPage] = [
        WelcomeOnboardingPage(
            title: "Manage Your Team",
            subtitle: "Organize team members, track roles, and coordinate activities all in one place. Build stronger teams with better communication.",
            imageName: "OnboardingManageTeam"
        ),
        WelcomeOnboardingPage(
            title: "Track Finances",
            subtitle: "Monitor budgets, track orders, and manage expenses. Stay on top of your team's financial health with detailed insights.",
            imageName: "OnboardingTrackFinances"
        ),
        WelcomeOnboardingPage(
            title: "Win with Data",
            subtitle: "Scout competitors, analyze performance, and make strategic decisions. Turn data into victories.",
            imageName: "OnboardingWinWithData"
        )
    ]
    
    var body: some View {
        ZStack {
            AuthLightTheme.introBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Simple Logo/Header Section
                VStack(spacing: 6) {
                    Text("FTCHUB")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    Text("Built for FIRST Tech Challenge teams")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AuthLightTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, DesignSystem.Spacing.xl)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Main Content - TabView for pages
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageContentView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .onChange(of: currentPage) {
                    stopAutoAdvance()
                    startAutoAdvance()
                }
                
                // Simple Pagination Dots
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.black : Color(UIColor(red: 0.82, green: 0.82, blue: 0.84, alpha: 1.0)))
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.lg)
                
                // Action Buttons
                VStack(spacing: DesignSystem.Spacing.md) {
                    Button(action: {
                        showingAuth = true
                        DesignSystem.Haptics.impact(.medium)
                    }) {
                        HStack {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .font(.body)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DesignSystem.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            authService.enterGuestMode()
                        }
                        DesignSystem.Haptics.impact(.light)
                    }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text("Continue as Guest")
                                .font(.body.weight(.semibold))
                            Image(systemName: "eye")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AuthLightTheme.guestButtonBackground)
                        .foregroundColor(AuthLightTheme.guestButtonForeground)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, 50)
            }
        }
        .authIntroScreen()
        .onAppear {
            startAutoAdvance()
        }
        .onDisappear {
            stopAutoAdvance()
        }
        .fullScreenCover(isPresented: $showingAuth) {
            AuthenticationView(
                showsCloseButton: true,
                onContinueAsGuest: {
                    showingAuth = false
                }
            )
            .environmentObject(authService)
        }
        .onChange(of: authService.isGuestMode) { _, isGuest in
            if isGuest {
                showingAuth = false
            }
        }
    }
    
    private func startAutoAdvance() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage = (currentPage + 1) % onboardingPages.count
            }
        }
    }
    
    private func stopAutoAdvance() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Onboarding Page Data
struct WelcomeOnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
}

// MARK: - Onboarding Page Content View
struct OnboardingPageContentView: View {
    let page: WelcomeOnboardingPage
    @State private var animationOffset: CGFloat = 50
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320, maxHeight: 280)
                .offset(y: animationOffset)
                .opacity(animationOpacity)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.xl)
                .accessibilityHidden(true)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .offset(y: animationOffset)
                    .opacity(animationOpacity)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(Color(UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .offset(y: animationOffset)
                    .opacity(animationOpacity)
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animationOffset = 0
                animationOpacity = 1
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthService())
}
