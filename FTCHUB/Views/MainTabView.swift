//
//  MainTabView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
import Combine
import UserNotifications

struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var toastManager: ToastManager
    @AppStorage("ftchub.colorScheme") private var colorSchemePreference: String = "light"
    @AppStorage("ftchub.savedTabGuest") private var savedTabGuest = 0
    @AppStorage("ftchub.savedTabNoTeam") private var savedTabNoTeam = 0
    @AppStorage("ftchub.savedTabWithTeam") private var savedTabWithTeam = 0
    @AppStorage("ftchub.dismissedNotificationRetentionBanner") private var dismissedNotificationBanner = false
    @StateObject private var teamService = TeamService()
    @StateObject private var inventoryService = InventoryService()
    @StateObject private var scoutingService = ScoutingService()
    @StateObject private var scheduleService = ScheduleService()
    @StateObject private var financeService = FinanceService.shared
    @StateObject private var offlineService = OfflineService()
    @State private var selectedTab = 0
    @State private var pulsingTabs: Set<Int> = []
    @State private var scoutingReportsBaseline = 0
    @State private var didRunRetentionHooks = false
    @State private var notificationsAuthorized = true
    @State private var showNotificationRetentionBanner = false
    @State private var suppressNextTabSelectionFeedback = false
    
    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "dark":
            return .dark
        case "light":
            return .light
        default:
            return nil // system
        }
    }
    
    /// Maps `ftchub://tab/...` paths to tab indices for guest, no-team, and full tab bars.
    private func applyMainTabDeeplink(path raw: String) {
        let p = raw.lowercased()
        if authService.isGuestMode {
            switch p {
            case "team", "resources", "": selectedTab = 0
            case "finance", "calculator": selectedTab = 1
            case "scouting", "timer": selectedTab = 2
            case "competition", "rules": selectedTab = 2
            case "settings", "more": selectedTab = 3
            default: selectedTab = 0
            }
            return
        }
        if teamService.currentTeam == nil {
            switch p {
            case "team", "": selectedTab = 0
            case "resources": selectedTab = 1
            case "finance", "calculator": selectedTab = 2
            case "scouting", "timer", "competition": selectedTab = 3
            case "rules": selectedTab = 4
            case "settings": selectedTab = 5
            default: selectedTab = 0
            }
            return
        }
        switch p {
        case "team", "": selectedTab = 0
        case "finance": selectedTab = 1
        case "scouting", "tools", "season", "notebook": selectedTab = 2
        case "competition", "timer", "rules", "calculator", "resources": selectedTab = 3
        case "settings": selectedTab = 4
        default: break
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                if authService.isGuestMode {
                // Guest mode - show Resources, Scoring Calculator, Drive Team Timer, and More
                FTCResourcesView()
                    .environmentObject(authService)
                    .tabItem {
                        tabLabel(title: "Resources", filledSystemImage: "book.fill", outlineSystemImage: "book", tabIndex: 0)
                    }
                    .tag(0)
                
                // Scoring Calculator - accessible in guest mode
                NavigationStack {
                    ScoringCalculatorView()
                }
                .tabItem {
                    tabLabel(title: "Calculator", filledSystemImage: "number.square.fill", outlineSystemImage: "number.square", tabIndex: 1)
                }
                .tag(1)
                
                // Drive Team Timer - accessible in guest mode
                NavigationStack {
                    DriveTeamTimerView()
                }
                .tabItem {
                    tabLabel(title: "Timer", filledSystemImage: "timer", outlineSystemImage: "timer", tabIndex: 2)
                }
                .tag(2)
                
                // Guest Settings / More tab
                GuestSettingsView()
                    .environmentObject(authService)
                    .tabItem {
                        tabLabel(title: "More", filledSystemImage: "ellipsis.circle.fill", outlineSystemImage: "ellipsis.circle", tabIndex: 3)
                    }
                    .tag(3)
                    } else if teamService.currentTeam == nil {
                // Authenticated but no team - Team tab first for discoverability, then Resources, Calculator, Timer, Rules
                TeamView()
                    .environmentObject(teamService)
                    .environmentObject(authService)
                    .tabItem {
                        tabLabel(title: "Team", filledSystemImage: "person.3.fill", outlineSystemImage: "person.3", tabIndex: 0)
                    }
                    .tag(0)
                
                FTCResourcesView()
                    .environmentObject(authService)
                    .tabItem {
                        tabLabel(title: "Resources", filledSystemImage: "book.fill", outlineSystemImage: "book", tabIndex: 1)
                    }
                    .tag(1)
                
                // Scoring Calculator - accessible without team
                NavigationStack {
                    ScoringCalculatorView()
                }
                .tabItem {
                    tabLabel(title: "Calculator", filledSystemImage: "number.square.fill", outlineSystemImage: "number.square", tabIndex: 2)
                }
                .tag(2)
                
                // Drive Team Timer - accessible without team
                NavigationStack {
                    DriveTeamTimerView()
                }
                .tabItem {
                    tabLabel(title: "Timer", filledSystemImage: "timer", outlineSystemImage: "timer", tabIndex: 3)
                }
                .tag(3)
                
                // Rules Reference - accessible without team
                NavigationStack {
                    RulesReferenceView()
                }
                .tabItem {
                    tabLabel(title: "Rules", filledSystemImage: "book.closed.fill", outlineSystemImage: "book.closed", tabIndex: 4)
                }
                .tag(4)
                
                // Settings
                EnhancedSettingsView()
                    .environmentObject(authService)
                    .environmentObject(teamService)
                    .environmentObject(inventoryService)
                    .environmentObject(scoutingService)
                    .environmentObject(scheduleService)
                    .environmentObject(financeService)
                    .tabItem {
                        tabLabel(title: "Settings", filledSystemImage: "gearshape.fill", outlineSystemImage: "gearshape", tabIndex: 5)
                    }
                    .tag(5)
                    } else {
                // Authenticated with team - show all tabs
                TeamView()
                    .environmentObject(teamService)
                    .environmentObject(authService)
                    .environmentObject(financeService)
                    .environmentObject(inventoryService)
                    .environmentObject(scoutingService)
                    .environmentObject(scheduleService)
                    .tabItem {
                        tabLabel(title: "Team", filledSystemImage: "person.3.fill", outlineSystemImage: "person.3", tabIndex: 0)
                    }
                    .tag(0)
                
                FinancialDashboardView()
                    .environmentObject(financeService)
                    .environmentObject(teamService)
                    .tabItem {
                        tabLabel(title: "Finance", filledSystemImage: "dollarsign.circle.fill", outlineSystemImage: "dollarsign.circle", tabIndex: 1)
                    }
                    .tag(1)
                
                TeamToolsHubView()
                    .environmentObject(scoutingService)
                    .environmentObject(teamService)
                    .environmentObject(scheduleService)
                    .environmentObject(inventoryService)
                    .tabItem {
                        tabLabel(title: "Tools", filledSystemImage: "wrench.and.screwdriver.fill", outlineSystemImage: "wrench.and.screwdriver", tabIndex: 2)
                    }
                    .tag(2)
                
                CompetitionView()
                    .environmentObject(scheduleService)
                    .environmentObject(teamService)
                    .environmentObject(scoutingService)
                    .environmentObject(offlineService)
                    .environmentObject(toastManager)
                    .tabItem {
                        tabLabel(title: "Competition", filledSystemImage: "trophy.fill", outlineSystemImage: "trophy", tabIndex: 3)
                    }
                    .tag(3)
                
                EnhancedSettingsView()
                    .environmentObject(authService)
                    .environmentObject(teamService)
                    .environmentObject(inventoryService)
                    .environmentObject(scoutingService)
                    .environmentObject(scheduleService)
                    .environmentObject(financeService)
                    .tabItem {
                        tabLabel(title: "Settings", filledSystemImage: "gearshape.fill", outlineSystemImage: "gearshape", tabIndex: 4)
                    }
                    .tag(4)
                    }
                }
            .frame(maxWidth: horizontalSizeClass == .regular ? 880 : .infinity)
            .frame(maxWidth: .infinity)
            .environmentObject(offlineService)
            .toolbarBackground(DesignSystem.Colors.tertiaryBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .tint(DesignSystem.Colors.primary)
            .preferredColorScheme(preferredColorScheme)
            
            // Offline pill — floats below the status bar as a non-intrusive overlay
            VStack {
                OfflineIndicator()
                    .environmentObject(offlineService)
                    .padding(.top, 8)
                Spacer()
            }
            .allowsHitTesting(true)
            .ignoresSafeArea(edges: [])
        
            if showNotificationRetentionBanner {
                NotificationRetentionBanner(
                    onEnable: {
                        Task {
                            await NotificationService.shared.requestAuthorization()
                            await refreshNotificationAuthorization()
                            if NotificationService.shared.isAuthorized {
                                showNotificationRetentionBanner = false
                                toastManager.showSuccess("Notifications on — we will keep event and match reminders timely.")
                            }
                        }
                    },
                    onDismiss: {
                        dismissedNotificationBanner = true
                        showNotificationRetentionBanner = false
                    }
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            teamService.bindAuthService(authService)
            restoreSelectedTab()
            RetentionEngagement.incrementLaunchCount()
            if !didRunRetentionHooks {
                didRunRetentionHooks = true
                if let msg = RetentionEngagement.takeWelcomeBackToastMessageIfNeeded() {
                    toastManager.showInfo(msg, duration: 4.0)
                }
            }
            Task {
                await refreshNotificationAuthorization()
            }
            // Only load data if not in preview mode
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                Task {
                    let initialTeamId = authService.currentUser?.teamId
                    await teamService.updateTeamContext(teamId: initialTeamId)
                    let teamId = teamService.currentTeam?.id ?? initialTeamId
                    inventoryService.updateTeamContext(teamId: teamId)
                    scoutingService.updateTeamContext(teamId: teamId)
                    scheduleService.updateTeamContext(teamId: teamId)
                    financeService.updateTeamContext(teamId: teamId)
                    scoutingReportsBaseline = scoutingService.scoutingReports.count
                }
            } else {
                scoutingReportsBaseline = scoutingService.scoutingReports.count
            }
        }
        .onReceive(authService.$currentUser) { profile in
            Task {
                let profileTeamId = profile?.teamId
                await teamService.updateTeamContext(teamId: profileTeamId)
                let teamId = teamService.currentTeam?.id ?? profileTeamId
                inventoryService.updateTeamContext(teamId: teamId)
                scoutingService.updateTeamContext(teamId: teamId)
                scheduleService.updateTeamContext(teamId: teamId)
                financeService.updateTeamContext(teamId: teamId)
            }
        }
        .onReceive(teamService.$currentTeam) { team in
            let teamId = team?.id ?? authService.currentUser?.teamId
            inventoryService.updateTeamContext(teamId: teamId)
            scoutingService.updateTeamContext(teamId: teamId)
            scheduleService.updateTeamContext(teamId: teamId)
            financeService.updateTeamContext(teamId: teamId)
            
            // Reset tab selection when team status changes to avoid showing wrong views
            // Tab 4 is Rules when no team, Settings when has team - need to reset
            if team != nil && selectedTab == 4 {
                // User just joined a team and was on Rules tab (4), reset to Team tab
                selectedTab = 0
            } else if team == nil && selectedTab == 4 {
                // User lost team and was on Settings tab (4), reset to Team tab
                selectedTab = 0
            } else if team != nil && selectedTab > 4 {
                // User just joined a team, but was on a tab that doesn't exist in team mode
                selectedTab = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ftcShowTeamTab)) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .ftchubMainTabDeeplink)) { note in
            if let path = note.userInfo?["path"] as? String {
                applyMainTabDeeplink(path: path)
            }
        }
        .onReceive(scheduleService.$importStatus) { status in
            if case .success = status {
                triggerTabPulse(for: 3)
            }
        }
        .onReceive(scheduleService.$pendingCompetitionAttention) { needsAttention in
            if needsAttention {
                triggerTabPulse(for: 3)
            }
        }
        .onReceive(scoutingService.$scoutingReports) { reports in
            let count = reports.count
            if scoutingReportsBaseline > 0, count > scoutingReportsBaseline {
                triggerTabPulse(for: 2)
            }
            scoutingReportsBaseline = count
        }
        .onReceive(NotificationCenter.default.publisher(for: .ftchubScoutReportQueuedLocally)) { _ in
            toastManager.showInfo("Report saved on this device. It will upload when you are back online.")
        }
        .onChange(of: selectedTab, initial: false) { _, newValue in
            if !suppressNextTabSelectionFeedback {
                DesignSystem.Haptics.selection()
            }
            suppressNextTabSelectionFeedback = false
            persistSelectedTab(newValue)
            if newValue == 3 {
                scheduleService.acknowledgeCompetitionAttention()
                pulsingTabs.remove(3)
            }
            if newValue == 2 {
                pulsingTabs.remove(2)
            }
        }
    }
    
    private func maxTabIndexForCurrentLayout() -> Int {
        if authService.isGuestMode { return 3 }
        if teamService.currentTeam == nil { return 5 }
        return 4
    }
    
    private func restoreSelectedTab() {
        let maxV = maxTabIndexForCurrentLayout()
        let stored: Int
        if authService.isGuestMode {
            stored = savedTabGuest
        } else if teamService.currentTeam == nil {
            stored = savedTabNoTeam
        } else {
            stored = savedTabWithTeam
        }
        suppressNextTabSelectionFeedback = true
        selectedTab = min(max(0, stored), maxV)
    }
    
    private func persistSelectedTab(_ value: Int) {
        if authService.isGuestMode {
            savedTabGuest = value
        } else if teamService.currentTeam == nil {
            savedTabNoTeam = value
        } else {
            savedTabWithTeam = value
        }
    }
    
    private func refreshNotificationAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            let authorized = settings.authorizationStatus == .authorized
            notificationsAuthorized = authorized
            if authorized {
                showNotificationRetentionBanner = false
                return
            }
            guard !dismissedNotificationBanner else {
                showNotificationRetentionBanner = false
                return
            }
            guard RetentionEngagement.launchCount >= 2 else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                showNotificationRetentionBanner = true
            }
        }
    }
    
    private func triggerTabPulse(for index: Int, duration: TimeInterval = 4) {
        pulsingTabs.insert(index)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            pulsingTabs.remove(index)
        }
    }
    
    @ViewBuilder
    private func tabLabel(title: String, filledSystemImage: String, outlineSystemImage: String, tabIndex: Int) -> some View {
        Label {
            Text(title)
        } icon: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: selectedTab == tabIndex ? filledSystemImage : outlineSystemImage)
                if pulsingTabs.contains(tabIndex) {
                    PulseBadge()
                        .offset(x: 8, y: -6)
                }
            }
        }
    }
}

private struct PulseBadge: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(DesignSystem.Colors.accent.opacity(0.4), lineWidth: 2)
                .frame(width: 16, height: 16)
                .scaleEffect(animate ? 1.5 : 1)
                .opacity(animate ? 0 : 1)
            Circle()
                .fill(DesignSystem.Colors.accent)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(DesignSystem.Motion.spring(response: 0.6, dampingFraction: 0.65).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

// MARK: - Enhanced Team View
struct TeamView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @State private var showingCreateTeam = false
    @State private var showingJoinTeam = false
    @State private var showingInviteCode = false
    
    var body: some View {
        NavigationStack {
            Group {
                if teamService.currentTeam == nil {
                    NoTeamView(
                        showingCreateTeam: $showingCreateTeam,
                        showingJoinTeam: $showingJoinTeam,
                        onRefresh: {
                            await teamService.loadTeamData()
                        }
                    )
                    .toolbarBackground(.hidden, for: .navigationBar)
                } else {
                    TeamDashboardView(showingInviteCode: $showingInviteCode)
                        .ftchubRootNavHeader(title: "Team")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if teamService.currentTeam != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingInviteCode = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                        }
                        .accessibilityLabel("Invite to team")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateTeam) {
            TeamCreationView()
                .environmentObject(teamService)
        }
        .sheet(isPresented: $showingJoinTeam) {
            TeamJoinView()
                .environmentObject(teamService)
        }
        .sheet(isPresented: $showingInviteCode) {
            NavigationView {
                InviteCodeView()
                    .environmentObject(teamService)
            }
        }
        .onAppear {
            // Ensure team data is loaded when view appears
            if teamService.currentTeam != nil {
                Task {
                    await teamService.loadTeamData()
                }
            }
        }
    }
}

struct NoTeamView: View {
    @Binding var showingCreateTeam: Bool
    @Binding var showingJoinTeam: Bool
    var onRefresh: () async -> Void = {}

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                NoTeamPrimaryCard(
                    showingCreateTeam: $showingCreateTeam,
                    showingJoinTeam: $showingJoinTeam,
                    stretchMinHeight: geo.size.height
                )
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .tabBarScrollInset()
            .refreshable { await onRefresh() }
        }
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - No-team Mobbin-style card clusters

private struct NoTeamPrimaryCard: View {
    @Binding var showingCreateTeam: Bool
    @Binding var showingJoinTeam: Bool
    /// When set, card fills at least this height (e.g. visible tab area) with flexible vertical spacing.
    var stretchMinHeight: CGFloat? = nil

    private let corner = DesignSystem.CornerRadius.lg

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Text("Your team's\ncommand center.")
                    .font(.title.bold())
                    .fontDesign(.rounded)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.85)
                    .accessibilityAddTraits(.isHeader)

                Text("Join or create a team to unlock finance, tools (scouting and engineering notebook), and competition helpers.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 2)
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Button(action: { showingCreateTeam = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                        Text("Create New Team")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystem.Gradients.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: corner))
                }
                .buttonStyle(SpringyButtonStyle())

                Button(action: { showingJoinTeam = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                        Text("Join Existing Team")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .background(DesignSystem.Colors.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: corner))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner)
                            .stroke(DesignSystem.Colors.separator, lineWidth: 1)
                    )
                }
                .buttonStyle(SpringyButtonStyle())
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: stretchMinHeight)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.45), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner)
                .stroke(DesignSystem.Colors.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

private struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

private struct FTCSeasonHintCard: View {
    @AppStorage("ftchub.dismissedFTCSeasonHint") private var dismissed = false
    
    var body: some View {
        if !dismissed {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "scope")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.primary)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FTC this season")
                            .font(.headline)
                        Text("Teams iterate on design and autonomous strategy for the annual challenge, then compete with alliances, judged awards, and gracious professionalism — the same rhythm this app supports between events.")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let url = URL(string: "https://www.firstinspires.org/robotics/ftc/game-and-season") {
                            Link("Official game & season materials", destination: url)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    Spacer(minLength: 0)
                    Button {
                        dismissed = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    .accessibilityLabel("Dismiss season tip")
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.backgroundElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

private struct NotificationRetentionBanner: View {
    let onEnable: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(DesignSystem.Colors.primary)
                Text("Stay in the loop")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .accessibilityLabel("Dismiss notification prompt")
            }
            Text("Turn on notifications for event reminders and match-day nudges. You control frequency in Settings.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Button(action: onEnable) {
                Text("Enable notifications")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DesignSystem.Gradients.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignSystem.Colors.primary.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

struct TeamDashboardView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @Binding var showingInviteCode: Bool
    @StateObject private var calendarService = SimplifiedCalendarService()
    @ObservedObject private var notificationService = NotificationService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Hero Card - Team Details (like the green header in the image)
                TeamHeroCard()
                    .environmentObject(teamService)
                    .environmentObject(authService)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.md)
                
                FTCSeasonHintCard()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Members List Section (like "Top designers" in the image)
                TeamMembersListSection()
                    .environmentObject(teamService)
                    .environmentObject(authService)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Content Sections
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Embedded Calendar
                    EmbeddedCalendarView()
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                    // Upcoming Items
                    UpcomingThingsCard()
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .refreshable {
            await teamService.loadTeamData()
        }
    }
}

// TeamHeaderCard removed - replaced with inline design in TeamDashboardView

// QuickActionsCard removed - replaced with inline design in TeamDashboardView

struct TeamQuickActionButton: View {
    let title: String
    let icon: String
    let count: Int?
    
    var body: some View {
        VStack(spacing: 8) {
            // Title - centered
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Action indicator - centered
            HStack(spacing: 4) {
                Text("View")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.primary.opacity(0.8))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90) // Reduced height
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    DesignSystem.Colors.border,
                    lineWidth: 1
                )
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// Custom button style for better visual feedback
struct TeamQuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct QuickStatsCard: View {
    @EnvironmentObject var teamService: TeamService
    
    // Computed property to ensure we only count valid events
    private var validEventsCount: Int {
        // Always filter to ensure we only count truly valid events
        guard let currentTeamId = teamService.currentTeam?.id else {
            return 0
        }
        
        // If events array is empty, return 0 immediately
        guard !teamService.events.isEmpty else {
            return 0
        }
        
        let validEvents = teamService.events.filter { event in
            // Title must not be empty after trimming whitespace and newlines
            let trimmedTitle = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { 
                return false 
            }
            
            // Title must have at least one non-whitespace character
            let hasNonWhitespace = trimmedTitle.unicodeScalars.contains { !CharacterSet.whitespacesAndNewlines.contains($0) }
            guard hasNonWhitespace else {
                return false
            }
            
            // Must have a valid team ID that matches current team
            guard event.teamId == currentTeamId else {
                return false
            }
            
            return true
        }
        
        return validEvents.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                Text("Quick Stats")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                StatItem(
                    title: "Events",
                    value: "\(validEventsCount)",
                    icon: "calendar",
                    color: DesignSystem.Colors.primary
                )
                
                StatItem(
                    title: "Tasks",
                    value: "\(teamService.tasks.count)",
                    icon: "checklist",
                    color: DesignSystem.Colors.accent
                )
                
                StatItem(
                    title: "Members",
                    value: "\(teamService.teamMembers.count)",
                    icon: "person.2",
                    color: DesignSystem.Colors.secondary
                )
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.12), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.2),
                                color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
    }
}

// MARK: - Embedded Calendar View
struct EmbeddedCalendarView: View {
    @EnvironmentObject var teamService: TeamService
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header with navigation
            HStack {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Calendar")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                // Month navigation
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .clipShape(Circle())
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)
            
            // Month and year display
            HStack {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xs)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xs)
            
            // Calendar grid
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
            let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                // Empty cells for days before month starts
                ForEach(0..<firstWeekday, id: \.self) { index in
                    Text("")
                        .frame(height: 44)
                        .id("empty-\(index)")
                }
                
                // Days of the month
                ForEach(1...daysInMonth, id: \.self) { day in
                    let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
                    let hasEvents = teamService.events.contains { event in
                        calendar.isDate(event.startDate, inSameDayAs: dayDate)
                    }
                    let hasTasks = teamService.tasks.contains { task in
                        if let dueDate = task.dueDate {
                            return calendar.isDate(dueDate, inSameDayAs: dayDate)
                        }
                        return false
                    }
                    let isToday = calendar.isDate(dayDate, inSameDayAs: Date())
                    
                    VStack(spacing: 4) {
                        Text("\(day)")
                            .font(.system(size: 14, weight: isToday ? .bold : .semibold, design: .rounded))
                            .foregroundColor(isToday ? .white : DesignSystem.Colors.textPrimary)
                        
                        if hasEvents || hasTasks {
                            HStack(spacing: 3) {
                                if hasEvents {
                                    Circle()
                                        .fill(isToday ? .white.opacity(0.9) : DesignSystem.Colors.primary)
                                        .frame(width: 4, height: 4)
                                }
                                if hasTasks {
                                    Circle()
                                        .fill(isToday ? .white.opacity(0.9) : DesignSystem.Colors.accent)
                                        .frame(width: 4, height: 4)
                                }
                            }
                        }
                    }
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(
                        Group {
                            if isToday {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DesignSystem.Colors.primary)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isToday ? Color.clear : DesignSystem.Colors.border.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                    .id("day-\(day)-\(selectedDate.formatted(.dateTime.month(.twoDigits).year()))")
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.xl)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
    }
}

struct UpcomingEventsCard: View {
    @EnvironmentObject var teamService: TeamService
    @StateObject private var calendarService = SimplifiedCalendarService()
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var showingEventsView = false
    
    var upcomingEvents: [Event] {
        teamService.events
            .filter { $0.startDate > Date() }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(alignment: .center) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    Text("Upcoming Events")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                Button("View All") {
                    showingEventsView = true
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                )
            }
            
            if upcomingEvents.isEmpty {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.textSecondary.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                    }
                    Text("No upcoming events")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(upcomingEvents) { event in
                        EventRowView(event: event)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.12), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingEventsView) {
            EventManagementView()
                .environmentObject(calendarService)
                .environmentObject(teamService)
                .environmentObject(notificationService)
        }
    }
}

// MARK: - Unified Item Row View
struct UpcomingItemRowView: View {
    let item: UpcomingItem
    let currentUserId: UUID?
    let onTap: () -> Void
    
    var isAssigned: Bool {
        item.isAssignedTo(userId: currentUserId)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
                // Icon based on type
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .fixedSize()
                    
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Type badge
                        Text(typeBadgeText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeBadgeColor)
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        // Date
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .fixedSize()
                            Text(dateString)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                        }
                        
                        // Assignment indicator for tasks
                        if isAssigned {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                    .fixedSize()
                                Text("Assigned to you")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        
                        // Additional info based on type
                        if case .task(let task) = item {
                            if task.isOverdue {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .fixedSize()
                                    Text("Overdue")
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.error)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch item {
        case .task:
            return "checklist"
        case .event(let event):
            return event.eventType.icon
        }
    }
    
    private var iconColor: Color {
        switch item {
        case .task:
            return DesignSystem.Colors.primary
        case .event(let event):
            return Color.fromString(event.eventType.color)
        }
    }
    
    private var iconBackgroundColor: Color {
        switch item {
        case .task:
            return DesignSystem.Colors.primary
        case .event(let event):
            return Color.fromString(event.eventType.color)
        }
    }
    
    private var typeBadgeText: String {
        switch item {
        case .task:
            return "Task"
        case .event:
            return "Event"
        }
    }
    
    private var typeBadgeColor: Color {
        switch item {
        case .task:
            return DesignSystem.Colors.primary
        case .event:
            return DesignSystem.Colors.accent
        }
    }
    
    private var dateString: String {
        switch item {
        case .task(let task):
            if let dueDate = task.dueDate {
                return dueDate.formatted(date: .abbreviated, time: .shortened)
            }
            return "No due date"
        case .event(let event):
            return event.startDate.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
            // Enhanced icon with background
            ZStack {
                Circle()
                    .fill(Color.fromString(event.eventType.color).opacity(0.15))
                    .frame(width: 40, height: 40)
                    .fixedSize()
                
                Image(systemName: event.eventType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.fromString(event.eventType.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .fixedSize()
                    Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct UpcomingThingsCard: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @StateObject private var calendarService = SimplifiedCalendarService()
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var showingAddItem = false
    @State private var showingEventsView = false
    @State private var showingTasksView = false
    @State private var selectedTask: TeamTask?
    @State private var selectedEvent: Event?
    @State private var showingTaskDetail: TeamTask?
    @State private var showingEventDetail: Event?
    
    // Combined upcoming items (tasks and events)
    var upcomingItems: [UpcomingItem] {
        let now = Date()
        var items: [UpcomingItem] = []
        
        // Add upcoming events (start date in future)
        let futureEvents = teamService.events.filter { $0.startDate > now }
        items.append(contentsOf: futureEvents.map { UpcomingItem.event($0) })
        
        // Add tasks with due dates in future, or no due date (show as upcoming)
        let futureTasks = teamService.tasks.filter { task in
            if let dueDate = task.dueDate {
                return dueDate > now || task.status != .done
            }
            return task.status != .done // Show incomplete tasks without due dates
        }
        items.append(contentsOf: futureTasks.map { UpcomingItem.task($0) })
        
        // Sort by date (upcoming items first)
        return items.sorted { $0.date < $1.date }.prefix(6).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header with title and Add button
            HStack {
                Text("Upcoming Items")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)
            
            // Combined list of tasks and events
            if upcomingItems.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.4))
                    Text("No upcoming items")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(upcomingItems) { item in
                        UpcomingItemRowView(
                            item: item,
                            currentUserId: authService.currentUser?.id,
                            onTap: {
                                handleItemTap(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // View All button
                HStack {
                    Spacer()
                    Button("View All") {
                        // Show combined view or let user choose
                        showingTasksView = true
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showingAddItem) {
            AddItemView()
                .environmentObject(teamService)
                .environmentObject(authService)
                .onDisappear {
                    Task {
                        await teamService.loadTeamData()
                        await calendarService.loadTeamEvents()
                    }
                }
        }
        .sheet(isPresented: $showingEventsView) {
            EventManagementView()
                .environmentObject(calendarService)
                .environmentObject(teamService)
                .environmentObject(notificationService)
        }
        .sheet(isPresented: $showingTasksView) {
            TasksView()
                .environmentObject(teamService)
                .environmentObject(authService)
        }
        .sheet(item: $showingTaskDetail) { task in
            TaskDetailView(task: task)
                .environmentObject(teamService)
                .environmentObject(authService)
                .onDisappear {
                    Task {
                        await teamService.loadTeamData()
                    }
                }
        }
        .onAppear {
            // Ensure calendar service has team context
            if let teamId = teamService.currentTeam?.id {
                calendarService.updateTeamContext(teamId: teamId)
            }
        }
    }
    
    private func handleItemTap(_ item: UpcomingItem) {
        switch item {
        case .task(let task):
            // Open TaskDetailView directly for viewing/editing/deleting
            showingTaskDetail = task
        case .event(let event):
            // For events, navigate to EventManagementView
            // User can then find and tap the event to view/edit/delete
            selectedEvent = event
            showingEventsView = true
        }
    }
}

struct RecentTasksCard: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @State private var showingTasksView = false
    
    var recentTasks: [TeamTask] {
        teamService.tasks.prefix(3).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(alignment: .center) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.accent.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "checklist")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    Text("Recent Tasks")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                Button("View All") {
                    showingTasksView = true
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.accent)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.accent.opacity(0.1))
                )
            }
            
            if recentTasks.isEmpty {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.textSecondary.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "checklist")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                    }
                    Text("No tasks yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(recentTasks) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.12), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingTasksView) {
            TasksView()
                .environmentObject(teamService)
                .environmentObject(authService)
        }
    }
}

struct TaskRowView: View {
    let task: TeamTask
    
    private var priorityColor: Color {
        switch task.priority {
        case .urgent: return DesignSystem.Colors.error
        case .high: return DesignSystem.Colors.warning
        case .medium: return DesignSystem.Colors.accent
        case .low: return DesignSystem.Colors.secondary
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
            // Enhanced status indicator
            ZStack {
                Circle()
                    .fill(Color.fromString(task.status.color).opacity(0.15))
                    .frame(width: 40, height: 40)
                    .fixedSize()
                
                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.fromString(task.status.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(task.status.displayName)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                    
                    // Priority badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 6, height: 6)
                            .fixedSize()
                        Text(task.priority.displayName)
                            .font(.caption2)
                            .foregroundColor(priorityColor)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if task.priority == .urgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.error)
                    .fixedSize()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}


struct ScoutingView: View {
    var embedsNavigationStack: Bool = true
    
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scheduleService: ScheduleService
    @State private var selectedTab = 0
    @State private var templateToDelete: ScoutingTemplate? = nil
    @State private var showingDeleteConfirmation = false
    
    var deletableTemplates: [ScoutingTemplate] {
        scoutingService.userDeletableTemplates
    }
    
    private var scoutingNavigationTitle: String {
        switch selectedTab {
        case 0: return "Team Explorer"
        case 1: return "Templates"
        default: return "Reports"
        }
    }
    
    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack {
                    scoutingRoot
                }
            } else {
                scoutingRoot
            }
        }
    }
    
    @ViewBuilder
    private var scoutingRoot: some View {
        Group {
            if scoutingService.hasTeamContext {
                scoutingContent
            } else {
                TeamAccessRequiredView(featureName: "Scouting")
            }
        }
        .background(DesignSystem.Colors.background)
        .toolbarBackground(DesignSystem.Colors.tertiaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !deletableTemplates.isEmpty {
                    Menu {
                        ForEach(deletableTemplates) { template in
                            Button(role: .destructive) {
                                templateToDelete = template
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete \(template.name)", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                templateToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    Task {
                        do {
                            try await scoutingService.deleteScoutingTemplate(template: template)
                        } catch {
                            DebugLog.log("Error deleting template: \(error)")
                        }
                    }
                }
                templateToDelete = nil
            }
        } message: {
            if let template = templateToDelete {
                Text("Are you sure you want to delete \"\(template.name)\"? This action cannot be undone.")
            }
        }
    }
    
    private var scoutingContent: some View {
        VStack(spacing: 0) {
            CustomScoutingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.sm)
            
            Group {
                switch selectedTab {
                case 0:
                    PublicDataExplorerHubView(scoutingSelectedTab: $selectedTab)
                        .environmentObject(teamService)
                        .environmentObject(scoutingService)
                        .environmentObject(scheduleService)
                case 1:
                    ScoutingTemplatesView(scoutingSelectedTab: $selectedTab, isEmbeddedInScoutingHub: true)
                        .environmentObject(scoutingService)
                        .environmentObject(teamService)
                        .environmentObject(scheduleService)
                default:
                    ScoutingReportsView(scoutingSelectedTab: $selectedTab, isEmbeddedInScoutingHub: true)
                        .environmentObject(scoutingService)
                        .environmentObject(teamService)
                        .environmentObject(scheduleService)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(scoutingNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: teamService.currentTeam?.id) { _, _ in
            selectedTab = 0
        }
        .onChange(of: scoutingService.hasTeamContext) { _, hasContext in
            selectedTab = 0
            if hasContext, ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                Task { await scoutingService.loadScoutingData() }
            }
        }
        .task {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                await scoutingService.loadScoutingData()
            }
        }
    }
}

struct CompetitionView: View {
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var teamService: TeamService
    
    var body: some View {
        NavigationStack {
            Group {
                if scheduleService.hasTeamContext {
                    competitionContent
                } else {
                    TeamAccessRequiredView(featureName: "Competition tools", message: "Join or create a team before using match schedules, timers, and competition helpers.")
                }
            }
            .ftchubRootNavHeader(title: "Competition")
            .background(DesignSystem.Colors.background)
        }
    }
    
    private var competitionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                competitionSection(title: "Match Day") {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        NavigationLink(destination: DriveTeamTimerView()) {
                            HubNavigationRow(
                                title: "Timer",
                                subtitle: "Match countdown timer",
                                icon: "timer",
                                tint: .orange
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: ScoringCalculatorView()) {
                            HubNavigationRow(
                                title: "Calculator",
                                subtitle: "Decode scoring calculator",
                                icon: "number.square.fill",
                                tint: .orange
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: MatchScheduleView()
                            .environmentObject(scheduleService)
                            .environmentObject(teamService)) {
                            HubNavigationRow(
                                title: "Schedule",
                                subtitle: "View and manage match schedule",
                                icon: "calendar",
                                tint: DesignSystem.Colors.primary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                competitionSection(title: "Reference") {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        NavigationLink(destination: RulesReferenceView()) {
                            HubNavigationRow(
                                title: "Rules",
                                subtitle: "Game manual and rule references",
                                icon: "book",
                                tint: .orange
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: FTCResourcesView().navigationBarTitleDisplayMode(.inline)) {
                            HubNavigationRow(
                                title: "Resources",
                                subtitle: "Official FTC resources and guides",
                                icon: "book.fill",
                                tint: .orange
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .tabBarScrollInset()
    }
    
    @ViewBuilder
    private func competitionSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            content()
        }
    }
}

struct CompetitionToolCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: DesignSystem.Colors.shadow, radius: 6, x: 0, y: 2)
        )
    }
}

struct UpcomingMatchPreview: View {
    let match: Match
    
    private var allianceAccent: Color {
        match.allianceColor == .red ? .red : .blue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Label("Next Match", systemImage: "flag.checkered")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(match.scheduledTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Match \(match.matchNumber)")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(match.allianceColor.displayName) Alliance")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(allianceAccent.opacity(0.15))
                        .foregroundColor(allianceAccent)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Label(match.scheduledTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if let location = match.location, !location.isEmpty {
                        Label(location, systemImage: "location")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

struct NoUpcomingMatchPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Label("No upcoming matches scheduled", systemImage: "calendar.badge.plus")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("Add matches manually to keep the drive team informed.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(DesignSystem.Gradients.primary)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(authService.currentUser?.initials ?? "?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(authService.currentUser?.displayName ?? "Unknown User")
                                .font(.headline)
                            Text(authService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    Button("Edit Profile") {
                        // Profile editing available through team member management
                    }
                    
                    Button("Change Password") {
                        // Password changes handled through authentication service
                    }
                }
                
                Section("Team") {
                    Button("Team Settings") {
                        // Team settings managed through team dashboard
                    }
                    
                    Button("Invite Members") {
                        // Member invitation available to team admins
                    }
                }
                
                Section("App") {
                    Button("Notifications") {
                        // Notification preferences managed in system settings
                    }
                    
                    Button("Data & Privacy") {
                        // Privacy settings available in app settings
                    }
                    
                    Button("Help & Support") {
                        // Support available via email: kartheek.eadara@gmail.com
                    }
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    // Use actual services but they will use mock data in preview mode
    let authService = AuthService()
    let teamService = TeamService()
    let inventoryService = InventoryService()
    let scoutingService = ScoutingService()
    
    return MainTabView()
        .environmentObject(authService)
        .environmentObject(teamService)
        .environmentObject(inventoryService)
        .environmentObject(scoutingService)
        .withToast()
}

// MARK: - Scouting Hub Scroll Header

struct ScoutingHubScrollHeader: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        CustomScoutingTabBar(selectedTab: $selectedTab)
    }
}

// MARK: - Custom Scouting Tab Bar
struct CustomScoutingTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let tabs: [(title: String, accessibilityTitle: String, icon: String, tag: Int)] = [
        ("Teams", "Find Teams", "magnifyingglass", 0),
        ("Templates", "Templates", "doc.on.doc.fill", 1),
        ("Reports", "Reports", "chart.bar.doc.horizontal.fill", 2)
    ]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.tag) { tab in
                Button {
                    withAnimation(reduceMotion ? .none : DesignSystem.Motion.spring(response: 0.30, dampingFraction: 0.78)) {
                        selectedTab = tab.tag
                    }
                    DesignSystem.Haptics.selection()
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(tab.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundColor(selectedTab == tab.tag ? DesignSystem.Colors.textOnPrimary : DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedTab == tab.tag {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .fill(DesignSystem.Gradients.primary)
                                .shadow(color: DesignSystem.Colors.primary.opacity(0.28), radius: 8, x: 0, y: 3)
                                .matchedGeometryEffect(id: "scoutingSelectedTab", in: animation)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.accessibilityTitle)
                .accessibilityAddTraits(selectedTab == tab.tag ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.borderSubtle.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Team Hero Card (Top Box with Team Details)
struct TeamHeroCard: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? DesignSystem.Colors.textPrimary : .white
    }
    
    private var buttonTextColor: Color {
        colorScheme == .dark ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.primary
    }
    
    private var buttonBackgroundColor: Color {
        colorScheme == .dark ? DesignSystem.Colors.tertiaryBackground : Color.white
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
            // Left side - Team Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Team Name
                Text(teamService.currentTeam?.name ?? "Team")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .lineLimit(2)
                
                // Team Number
                Text("Team \(teamService.currentTeam?.number ?? "?")")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor.opacity(0.9))
                
                // Location
                if let location = teamService.currentTeam?.location {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textColor.opacity(0.8))
                        Text(location)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(textColor.opacity(0.9))
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
                
                // Action Button
                NavigationLink(destination: TeamRolesView()
                    .environmentObject(teamService)
                    .environmentObject(authService)) {
                    Text("Manage Team")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(buttonTextColor)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(buttonBackgroundColor)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .padding(.top, DesignSystem.Spacing.sm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if colorScheme == .dark {
                    Color(red: 0.28, green: 0.18, blue: 0.12)
                } else {
                    DesignSystem.Colors.primary
                }
            }
        )
        .cornerRadius(DesignSystem.CornerRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(
                    colorScheme == .dark 
                        ? DesignSystem.Colors.primary.opacity(0.3)
                        : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(color: DesignSystem.Colors.primary.opacity(colorScheme == .dark ? 0.25 : 0.2), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Team Members List Section
struct TeamMembersListSection: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @State private var showingMembersView = false
    
    var displayedMembers: [Profile] {
        Array(teamService.teamMembers.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Members List
            if displayedMembers.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "person.3")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.4))
                    Text("No members yet")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(displayedMembers) { member in
                        TeamMemberPillCard(member: member)
                            .environmentObject(teamService)
                            .environmentObject(authService)
                    }
                }
            }
        }
    }
}

// MARK: - Team Member Pill Card
struct TeamMemberPillCard: View {
    let member: Profile
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationLink(destination: MemberDetailView(member: member)
            .environmentObject(teamService)
            .environmentObject(authService)) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarBackgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Text(initials)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Member Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(roleDescription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Action Button (chevron like in the image)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .frame(width: 24, height: 24)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var fullName: String {
        member.displayName
    }
    
    private var initials: String {
        member.initials
    }
    
    private var roleDescription: String {
        var parts: [String] = []
        
        if let teamRole = member.teamRole {
            parts.append(teamRole.displayName)
        }
        
        if let memberRole = member.memberRole {
            parts.append(memberRole.displayName)
        }
        
        return parts.isEmpty ? "Member" : parts.joined(separator: " • ")
    }
    
    private var avatarBackgroundColor: Color {
        // Generate consistent color based on member ID with more color variety
        let colors: [Color] = [
            DesignSystem.Colors.primary,
            DesignSystem.Colors.accent,
            Color(red: 0.4, green: 0.6, blue: 0.8), // Blue
            Color(red: 0.8, green: 0.5, blue: 0.3), // Orange
            Color(red: 0.5, green: 0.7, blue: 0.5), // Green
            Color(red: 0.7, green: 0.5, blue: 0.8), // Purple
            Color(red: 0.6, green: 0.8, blue: 0.7), // Mint
        ]
        let index = abs(member.id.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Member Detail View
struct MemberDetailView: View {
    let member: Profile
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    
    var assignedTasks: [TeamTask] {
        teamService.tasks.filter { task in
            task.allAssigneeIds.contains(member.id)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                // Member Header
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(avatarBackgroundColor)
                            .frame(width: 60, height: 60)
                        
                        Text(member.initials)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.displayName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(roleDescription)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.xl)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 2)
                
                // Assigned Tasks Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Assigned Tasks")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    if assignedTasks.isEmpty {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "checklist")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.4))
                            Text("No tasks assigned to this person at this time")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.xl)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    } else {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(assignedTasks) { task in
                                TaskRowCard(task: task)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                
                // Events Section (showing all team events since events aren't assigned to individuals)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Team Events")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    if teamService.events.isEmpty {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "calendar")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.4))
                            Text("No events scheduled")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.xl)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    } else {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(teamService.events.prefix(10)) { event in
                                EventRowCard(event: event)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .navigationTitle("Member Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var roleDescription: String {
        var parts: [String] = []
        
        if let teamRole = member.teamRole {
            parts.append(teamRole.displayName)
        }
        
        if let memberRole = member.memberRole {
            parts.append(memberRole.displayName)
        }
        
        return parts.isEmpty ? "Member" : parts.joined(separator: " • ")
    }
    
    private var avatarBackgroundColor: Color {
        let colors: [Color] = [
            DesignSystem.Colors.primary,
            DesignSystem.Colors.accent,
            Color(red: 0.4, green: 0.6, blue: 0.8),
            Color(red: 0.8, green: 0.5, blue: 0.3),
            Color(red: 0.5, green: 0.7, blue: 0.5),
        ]
        let index = abs(member.id.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Task Row Card
struct TaskRowCard: View {
    let task: TeamTask
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Priority badge
            Text(task.priority.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(priorityColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor.opacity(0.15))
                .cornerRadius(DesignSystem.CornerRadius.sm)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 6, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch task.status {
        case .done: return DesignSystem.Colors.success
        case .doing: return DesignSystem.Colors.primary
        case .todo: return DesignSystem.Colors.textSecondary
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

// MARK: - Event Row Card
struct EventRowCard: View {
    let event: Event
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // Event type icon
            ZStack {
                Circle()
                    .fill(Color.fromString(event.eventType.color).opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: event.eventType.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.fromString(event.eventType.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// Mock services removed - using actual services with preview mode handling
