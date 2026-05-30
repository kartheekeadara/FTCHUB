import SwiftUI

struct EventManagementView: View {
    @EnvironmentObject private var calendarService: SimplifiedCalendarService
    @EnvironmentObject private var teamService: TeamService
    @EnvironmentObject private var notificationService: NotificationService
    
    @State private var editorMode: EventEditorMode?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var eventPendingDeletion: Event?
    @State private var selectedFilter: EventFilter = .upcoming
    @State private var selectedDate = Date()
    
    private var hasTeam: Bool { teamService.currentTeam != nil }
    
    private var upcomingEvents: [Event] {
        let now = Date()
        return calendarService.teamEvents.filter { $0.startDate >= now }
            .sorted { $0.startDate < $1.startDate }
    }
    
    private var pastEvents: [Event] {
        let now = Date()
        return calendarService.teamEvents.filter { $0.startDate < now }
            .sorted { $0.startDate > $1.startDate }
    }
    
    private var filteredEvents: [Event] {
        switch selectedFilter {
        case .upcoming:
            return upcomingEvents
        case .past:
            return pastEvents
        case .all:
            return calendarService.teamEvents.sorted { $0.startDate < $1.startDate }
        }
    }
    
    private var eventsForSelectedDate: [Event] {
        let calendar = Calendar.current
        return calendarService.teamEvents.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: selectedDate)
        }
        .sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if !hasTeam {
                    ContentUnavailableView {
                        Label(L10n.Settings.teamUnavailableTitle, systemImage: "person.3")
                    } description: {
                        Text(L10n.Settings.teamUnavailableMessage)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Date selector header
                        dateSelectorHeader
                        
                        // Timeline content
                        if isProcessing {
                            ProgressView("Loading events...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let errorMessage = calendarService.errorMessage {
                            errorView(message: errorMessage)
                        } else {
                            eventsTimelineContentView
                        }
                    }
                    .background(DesignSystem.Colors.background.ignoresSafeArea())
                }
            }
            .navigationTitle(L10n.Settings.eventManagementTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentCreateEditor()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(DesignSystem.Gradients.primary)
                    }
                    .disabled(!hasTeam)
                    .accessibilityLabel(L10n.Settings.eventsAddAction)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if calendarService.isConnected {
                        Button {
                            Task { await calendarService.loadCalendarEvents() }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        .accessibilityLabel(L10n.Settings.eventsRefreshCalendar)
                    }
                }
            }
            .task {
                await ensureTeamContext()
            }
            .refreshable {
                await refreshEvents()
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .alert(L10n.Settings.eventsDeleteConfirmTitle, isPresented: Binding(
                get: { eventPendingDeletion != nil },
                set: { if !$0 { eventPendingDeletion = nil } }
            )) {
                Button(L10n.Settings.eventsDeleteAction, role: .destructive) {
                    if let event = eventPendingDeletion {
                        Task { await deleteEvent(event) }
                    }
                }
                Button(L10n.General.actionClose, role: .cancel) {
                    eventPendingDeletion = nil
                }
            } message: {
                if let event = eventPendingDeletion {
                    Text(L10n.Settings.eventsDeleteConfirmMessage(event.title))
                }
            }
            .alert(L10n.Settings.eventsErrorTitle, isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(L10n.General.actionClose, role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(item: $editorMode) { mode in
                EventEditorView(
                    title: mode.navigationTitle,
                    draft: mode.draft,
                    calendarConnected: calendarService.isConnected,
                    notificationsAuthorized: notificationService.isAuthorized,
                    onSave: { draft in
                        Task { await handleSave(draft: draft, mode: mode) }
                    },
                    onDelete: mode.isEditing ? {
                        if case .edit(let event, _) = mode {
                            eventPendingDeletion = event
                            editorMode = nil
                        }
                    } : nil,
                    onCancel: { editorMode = nil }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Date Selector Header
    private var dateSelectorHeader: some View {
        VStack(spacing: 0) {
            // Week navigation
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        let calendar = Calendar.current
                        if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
                
                Text(weekRangeString)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        let calendar = Calendar.current
                        if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            
            // Day selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(weekDates, id: \.self) { date in
                        EventDaySelectorButton(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            eventCount: eventsForDate(date)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDate = date
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .padding(.bottom, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.cardBackground)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 4, x: 0, y: 2)
    }
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? selectedDate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: startOfWeek)
        
        if calendar.isDate(startOfWeek, equalTo: endOfWeek, toGranularity: .month) {
            formatter.dateFormat = "d"
            let endDay = formatter.string(from: endOfWeek)
            formatter.dateFormat = "MMMM yyyy"
            let monthYear = formatter.string(from: startOfWeek)
            return "\(startString) - \(endDay), \(monthYear)"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
        }
    }
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private func eventsForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        return calendarService.teamEvents.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }.count
    }
    
    // MARK: - Events Timeline Content View
    private var eventsTimelineContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if eventsForSelectedDate.isEmpty {
                    emptyStateView
                        .padding(.top, DesignSystem.Spacing.xl * 2)
                } else {
                    // Timeline with events
                    EventTimelineLayoutView(events: eventsForSelectedDate, selectedDate: selectedDate) { event in
                        presentEditEditor(for: event)
                    }
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(DesignSystem.Colors.error)
            
            Text("Error Loading Events")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Button("Retry") {
                Task {
                    await refreshEvents()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
            
            Text("No Events")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("No events scheduled for this day")
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            if hasTeam {
                Button(L10n.Settings.eventsAddAction) {
                    presentCreateEditor()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(DesignSystem.Gradients.primary)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func presentCreateEditor() {
        guard let start = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) else {
            editorMode = .create(EventDraft(syncToCalendar: calendarService.isConnected, scheduleReminder: notificationService.isAuthorized))
            return
        }
        let draft = EventDraft(
            startDate: start,
            endDate: start.addingTimeInterval(3600),
            syncToCalendar: calendarService.isConnected,
            scheduleReminder: notificationService.isAuthorized
        )
        editorMode = .create(draft)
    }
    
    private func presentEditEditor(for event: Event) {
        let draft = EventDraft(event: event)
        editorMode = .edit(event, draft)
    }
    
    private func ensureTeamContext() async {
        guard let teamId = teamService.currentTeam?.id ?? teamService.teamMembers.first?.teamId else {
            return
        }
        calendarService.updateTeamContext(teamId: teamId)
        await refreshEvents()
    }
    
    private func refreshEvents() async {
        await calendarService.loadTeamEvents()
    }
    
    private func handleSave(draft: EventDraft, mode: EventEditorMode) async {
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = L10n.Settings.eventsValidationMessage
            return
        }
        
        isProcessing = true
        do {
            let savedEvent: Event
            switch mode {
            case .create:
                savedEvent = try await calendarService.createTeamEvent(from: draft)
            case .edit(let event, _):
                savedEvent = try await calendarService.updateTeamEvent(event, with: draft)
            }
            
            if draft.syncToCalendar {
                try? await calendarService.syncEventToDeviceCalendar(savedEvent)
            }
            
            if draft.scheduleReminder {
                notificationService.rescheduleEventReminder(for: savedEvent, minutesBefore: draft.reminderMinutesBefore)
            } else {
                notificationService.cancelEventReminders(eventId: savedEvent.id)
            }
            
            editorMode = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
    
    private func deleteEvent(_ event: Event) async {
        isProcessing = true
        do {
            notificationService.cancelEventReminders(eventId: event.id)
            try await calendarService.deleteTeamEvent(event)
            eventPendingDeletion = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
}

// MARK: - Supporting Types
enum EventFilter: CaseIterable {
    case upcoming, past, all
    
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .past: return "Past"
        case .all: return "All"
        }
    }
}

fileprivate enum EventEditorMode: Identifiable {
    case create(EventDraft)
    case edit(Event, EventDraft)
    
    var id: UUID {
        switch self {
        case .create(let draft): return draft.id
        case .edit(let event, _): return event.id
        }
    }
    
    var draft: EventDraft {
        switch self {
        case .create(let draft): return draft
        case .edit(_, let draft): return draft
        }
    }
    
    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }
    
    var navigationTitle: String {
        switch self {
        case .create:
            return L10n.Settings.eventsCreateTitle
        case .edit(let event, _):
            return L10n.Settings.eventsEditTitle(event.title)
        }
    }
}

// MARK: - Event Stat Card
fileprivate struct EventStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Event Filter Chip
fileprivate struct EventFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            DesignSystem.Gradients.primary
        } else {
            DesignSystem.Colors.cardBackground
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(backgroundView)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(isSelected ? Color.clear : DesignSystem.Colors.border.opacity(0.3), lineWidth: 1.5)
                )
                .cornerRadius(DesignSystem.CornerRadius.md)
                .shadow(color: isSelected ? DesignSystem.Colors.primary.opacity(0.2) : DesignSystem.Colors.shadow.opacity(0.05), radius: isSelected ? 6 : 2, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Event Timeline Layout View
private struct EventTimelineLayoutView: View {
    let events: [Event]
    let selectedDate: Date
    let onEventTap: (Event) -> Void
    
    // Generate time slots from 6 AM to 11 PM
    private var timeSlots: [Date] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        var slots: [Date] = []
        
        for hour in 6..<23 {
            for minute in [0, 30] {
                if let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) {
                    slots.append(date)
                }
            }
        }
        return slots
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Time markers background
            VStack(alignment: .leading, spacing: 0) {
                ForEach(timeSlots.indices, id: \.self) { index in
                    if index % 2 == 0 { // Show every hour
                        EventTimeMarkerRow(time: timeSlots[index])
                            .frame(height: 60)
                    } else {
                        Spacer()
                            .frame(height: 60)
                    }
                }
            }
            .padding(.leading, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.md)
            
            // Event blocks
            VStack(alignment: .leading, spacing: 0) {
                ForEach(events) { event in
                    EventTimelineBlock(event: event, onTap: onEventTap)
                }
            }
            .padding(.leading, 100) // Offset for time markers
            .padding(.top, DesignSystem.Spacing.md)
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
}

// MARK: - Event Time Marker Row
private struct EventTimeMarkerRow: View {
    let time: Date
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Text(timeString)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 70, alignment: .trailing)
            
            Rectangle()
                .fill(DesignSystem.Colors.border.opacity(0.3))
                .frame(height: 1)
        }
    }
}

// MARK: - Event Timeline Block
private struct EventTimelineBlock: View {
    let event: Event
    let onTap: (Event) -> Void
    
    private var eventTypeColor: Color {
        switch event.eventType {
        case .practice: return .blue
        case .competition: return .orange
        case .meeting: return .green
        case .outreach: return .purple
        }
    }
    
    private var eventTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate ?? event.startDate.addingTimeInterval(3600))
        
        return "\(startTime) - \(endTime)"
    }
    
    private var eventTopOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        
        // Calculate offset from 6 AM (starting point)
        let startHour = 6
        let totalMinutes = (hour - startHour) * 60 + minute
        let slotHeight: CGFloat = 60 // Height per 30-minute slot
        return CGFloat(totalMinutes / 30) * slotHeight
    }
    
    var body: some View {
        Button(action: { onTap(event) }) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(eventTimeRange)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        if let description = event.description, !description.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.7))
                            Text(description)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                Image(systemName: event.eventType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                eventTypeColor.opacity(0.9),
                                eventTypeColor.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(eventTypeColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: eventTypeColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .offset(y: eventTopOffset)
        .padding(.trailing, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

// MARK: - Event Day Selector Button
private struct EventDaySelectorButton: View {
    let date: Date
    let isSelected: Bool
    let eventCount: Int
    let action: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(dayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                
                Text(dayNumber)
                    .font(.system(size: 18, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        ZStack {
                            if isSelected {
                                DesignSystem.Gradients.primary
                            } else if eventCount > 0 {
                                DesignSystem.Colors.primary.opacity(0.1)
                            } else {
                                DesignSystem.Colors.tertiaryBackground
                            }
                        }
                        .clipShape(Circle())
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.clear : DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                    )
                
                if eventCount > 0 {
                    Circle()
                        .fill(isSelected ? Color.white : DesignSystem.Colors.primary)
                        .frame(width: 4, height: 4)
                } else {
                    Spacer()
                        .frame(height: 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Event Card Block
private struct EventCardBlock: View {
    let event: Event
    let onTap: (Event) -> Void
    
    private var eventTypeColor: Color {
        switch event.eventType {
        case .practice: return .blue
        case .competition: return .orange
        case .meeting: return .green
        case .outreach: return .purple
        }
    }
    
    private var statusColor: Color {
        switch event.status {
        case .scheduled: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled: return .red
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
    
    private var durationString: String {
        let hours = Int(event.duration / 3600)
        let minutes = Int((event.duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 && minutes > 0 {
            return "\(hours) hrs \(minutes) min"
        } else if hours > 0 {
            return "\(hours) hrs"
        } else {
            return "\(minutes) min"
        }
    }
    
    var body: some View {
        Button(action: { onTap(event) }) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                // Time and icon
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ZStack {
                        Circle()
                            .fill(eventTypeColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: event.eventType.icon)
                            .font(.system(size: 18))
                            .foregroundColor(eventTypeColor)
                    }
                }
                
                // Event details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(event.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Status badge
                        Text(event.status.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    HStack(spacing: 12) {
                        Label(durationString, systemImage: "clock")
                            .font(.system(size: 13))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        if let location = event.location, !location.isEmpty {
                            Label(location, systemImage: "mappin.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    if let description = event.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.cardBackground,
                                DesignSystem.Colors.cardBackground.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(eventTypeColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                // Delete action handled in parent
            } label: {
                Label(L10n.Settings.eventsDeleteAction, systemImage: "trash")
            }
            .tint(.red)
        }
    }
}

// MARK: - Event Editor (Redesigned to match CreateTaskView)
private struct EventEditorView: View {
    @EnvironmentObject var teamService: TeamService
    
    let title: String
    let calendarConnected: Bool
    let notificationsAuthorized: Bool
    var onSave: (EventDraft) -> Void
    var onDelete: (() -> Void)?
    var onCancel: () -> Void
    
    @State private var draft: EventDraft
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(
        title: String,
        draft: EventDraft,
        calendarConnected: Bool,
        notificationsAuthorized: Bool,
        onSave: @escaping (EventDraft) -> Void,
        onDelete: (() -> Void)?,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self._draft = State(initialValue: draft)
        self.calendarConnected = calendarConnected
        self.notificationsAuthorized = notificationsAuthorized
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
    }
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: draft.startDate)
    }
    
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTime = formatter.string(from: draft.startDate)
        let endTime = formatter.string(from: draft.endDate)
        return "\(startTime) - \(endTime)"
    }
    
    private var durationString: String {
        let duration = draft.endDate.timeIntervalSince(draft.startDate)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 && minutes > 0 {
            return "\(hours) hrs \(minutes) min"
        } else if hours > 0 {
            return "\(hours) hrs"
        } else {
            return "\(minutes) min"
        }
    }
    
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .practice: return .blue
        case .competition: return .orange
        case .meeting: return .green
        case .outreach: return .purple
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Project/Team header
                    if let team = teamService.currentTeam {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(team.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text("Team Event")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Event type selector
                            Menu {
                                ForEach(EventType.allCases, id: \.self) { typeOption in
                                    Button {
                                        draft.eventType = typeOption
                                    } label: {
                                        HStack {
                                            Circle()
                                                .fill(eventTypeColor(typeOption))
                                                .frame(width: 12, height: 12)
                                            Text(typeOption.displayName)
                                            if draft.eventType == typeOption {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(eventTypeColor(draft.eventType))
                                        .frame(width: 10, height: 10)
                                    Text(draft.eventType.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(DesignSystem.Colors.primary.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Event name
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Event name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("Enter event name", text: $draft.title)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Location
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Location")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("Enter location (optional)", text: $draft.location)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Timeline")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            // Date
                            Button {
                                showingDatePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                    Text(dateRangeString)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(DesignSystem.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            
                            // Time range
                            Button {
                                showingTimePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14))
                                    Text(timeRangeString)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(DesignSystem.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .sheet(isPresented: $showingDatePicker) {
                        DatePickerSheet(
                            selectedDate: Binding(
                                get: { draft.startDate },
                                set: { newDate in
                                    let calendar = Calendar.current
                                    let timeComponents = calendar.dateComponents([.hour, .minute], from: draft.startDate)
                                    if let updatedDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: newDate) {
                                        draft.startDate = updatedDate
                                        // Update end date to maintain duration
                                        let duration = draft.endDate.timeIntervalSince(draft.startDate)
                                        draft.endDate = updatedDate.addingTimeInterval(duration)
                                    }
                                }
                            )
                        )
                        .presentationDetents([.height(300)])
                    }
                    .sheet(isPresented: $showingTimePicker) {
                        TimeRangePickerSheet(
                            startDate: $draft.startDate,
                            endDate: $draft.endDate
                        )
                        .presentationDetents([.height(400)])
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Description")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        ZStack(alignment: .topLeading) {
                            if draft.notes.isEmpty {
                                Text("Add a description...")
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $draft.notes)
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Save button
                    Button {
                        Task {
                            await saveEvent()
                        }
                    } label: {
                        Text(title.contains("Edit") ? "Save event" : "Add event")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Gradients.primary)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Delete button (only for editing)
                    if let onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Text("Delete event")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(DesignSystem.Colors.error.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.sm)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func saveEvent() async {
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Event name is required"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        await MainActor.run {
            onSave(draft)
        }
        
        isSaving = false
    }
}

// MARK: - Date Picker Sheet
private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Time Range Picker Sheet
private struct TimeRangePickerSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Start Time") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                }
                
                Section("End Time") {
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
