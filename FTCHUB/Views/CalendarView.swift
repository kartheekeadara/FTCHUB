//
//  CalendarView.swift
//  FTCHUB
//
//  Calendar view showing events and tasks with full CRUD functionality
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var calendarService: SimplifiedCalendarService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var editorMode: CalendarEditorMode?
    @State private var selectedTask: TeamTask?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    private var calendarItems: [CalendarItem] {
        var items: [CalendarItem] = []
        
        // Add events
        for event in teamService.events {
            items.append(.event(event))
        }
        
        // Add tasks with due dates
        for task in teamService.tasks {
            if let dueDate = task.dueDate {
                items.append(.task(task, dueDate: dueDate))
            }
        }
        
        return items.sorted { item1, item2 in
            item1.date < item2.date
        }
    }
    
    private var itemsForSelectedDate: [CalendarItem] {
        calendarItems.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            calendarContent
                .background(DesignSystem.Colors.background)
                .navigationTitle("Calendar")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        toolbarMenu
                    }
                }
                .overlay {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
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
                .sheet(item: $editorMode) { mode in
                    sheetContent(for: mode)
                }
                .task {
                    await ensureTeamContext()
                }
                .refreshable {
                    await refreshData()
                }
                .onChange(of: editorMode) { oldValue, newValue in
                    handleEditorModeChange(oldValue: oldValue, newValue: newValue)
                }
        }
    }
    
    private var calendarContent: some View {
        VStack(spacing: 0) {
            // Custom Calendar with Task Indicators
            CustomCalendarView(
                selection: $selectedDate,
                tasks: teamService.tasks,
                events: teamService.events
            )
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            
            Divider()
            
            // Items for selected date
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    if itemsForSelectedDate.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(itemsForSelectedDate, id: \.id) { item in
                            CalendarItemRow(item: item) {
                                presentEditItem(item)
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Large calendar icon with exclamation
            ZStack {
                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                    .offset(x: 30, y: 30)
            }
            
            // Title and description
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No items")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("No events or tasks scheduled for this date.")
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            HStack(spacing: DesignSystem.Spacing.md) {
                // Primary action button for events - gradient style
                Button {
                    presentCreateEvent()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("New Event")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.8),
                                Color.orange.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                // Secondary action button for tasks - outlined style
                Button {
                    presentCreateTask()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "checklist")
                            .font(.system(size: 16, weight: .semibold))
                        Text("New Task")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .frame(maxWidth: 600)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, DesignSystem.Spacing.xl)
    }
    
    private var toolbarMenu: some View {
        Menu {
            Button {
                presentCreateEvent()
            } label: {
                Label("New Event", systemImage: "calendar.badge.plus")
            }
            
            Button {
                presentCreateTask()
            } label: {
                Label("New Task", systemImage: "checklist")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(DesignSystem.Gradients.primary)
        }
    }
    
    @ViewBuilder
    private func sheetContent(for mode: CalendarEditorMode) -> some View {
        switch mode {
        case .createEvent(let draft):
            CalendarEventEditorView(
                title: "New Event",
                draft: draft,
                calendarConnected: calendarService.isConnected,
                notificationsAuthorized: notificationService.isAuthorized,
                onSave: { draft in
                    Task { await handleSaveEvent(draft: draft, mode: mode) }
                },
                onDelete: nil,
                onCancel: { editorMode = nil }
            )
            .presentationDetents([.medium, .large])
            
        case .editEvent(let event, let draft):
            CalendarEventEditorView(
                title: "Edit Event",
                draft: draft,
                calendarConnected: calendarService.isConnected,
                notificationsAuthorized: notificationService.isAuthorized,
                onSave: { draft in
                    Task { await handleSaveEvent(draft: draft, mode: mode) }
                },
                onDelete: {
                    Task { await handleDeleteEvent(event) }
                },
                onCancel: { editorMode = nil }
            )
            .presentationDetents([.medium, .large])
            
        case .createTask:
            CreateTaskView(
                selectedDate: selectedDate,
                onTaskCreated: {
                    // Dismiss immediately on main thread to prevent re-presentation
                    Task { @MainActor in
                        editorMode = nil
                        await refreshData()
                    }
                },
                onCancel: {
                    editorMode = nil
                }
            )
            .environmentObject(teamService)
            .environmentObject(authService)
            
        case .editTask(let task):
            TaskDetailViewWrapper(
                task: task,
                onDismiss: {
                    editorMode = nil
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await refreshData()
                    }
                }
            )
            .environmentObject(teamService)
            .environmentObject(authService)
        }
    }
    
    private func handleEditorModeChange(oldValue: CalendarEditorMode?, newValue: CalendarEditorMode?) {
        // When sheet is dismissed (newValue is nil), refresh data
        // Only refresh if we're not already in the process of creating a task
        if oldValue != nil && newValue == nil {
            // Skip refresh if we just created a task (it will refresh itself)
            if case .createTask = oldValue {
                // Don't refresh here - let the onTaskCreated callback handle it
                return
            }
            // Sheet was dismissed - refresh after a delay
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await refreshData()
            }
        }
    }
    
    private func ensureTeamContext() async {
        guard let teamId = teamService.currentTeam?.id ?? teamService.teamMembers.first?.teamId else {
            return
        }
        calendarService.updateTeamContext(teamId: teamId)
        await refreshData()
    }
    
    private func refreshData() async {
        await teamService.loadTeamData()
        await calendarService.loadTeamEvents()
    }
    
    private func presentCreateEvent() {
        guard let start = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: selectedDate) else {
            let draft = EventDraft(
                startDate: selectedDate,
                endDate: selectedDate.addingTimeInterval(3600),
                syncToCalendar: calendarService.isConnected,
                scheduleReminder: notificationService.isAuthorized
            )
            editorMode = .createEvent(draft)
            return
        }
        let draft = EventDraft(
            startDate: start,
            endDate: start.addingTimeInterval(3600),
            syncToCalendar: calendarService.isConnected,
            scheduleReminder: notificationService.isAuthorized
        )
        editorMode = .createEvent(draft)
    }
    
    private func presentCreateTask() {
        // Only present if not already presenting
        guard editorMode == nil else { return }
        editorMode = .createTask
    }
    
    private func presentEditItem(_ item: CalendarItem) {
        switch item {
        case .event(let event):
            let draft = EventDraft(event: event)
            editorMode = .editEvent(event, draft)
        case .task(let task, _):
            editorMode = .editTask(task)
        }
    }
    
    private func handleSaveEvent(draft: EventDraft, mode: CalendarEditorMode) async {
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Event title is required"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let savedEvent: Event
            switch mode {
            case .createEvent:
                savedEvent = try await calendarService.createTeamEvent(from: draft)
            case .editEvent(let event, _):
                savedEvent = try await calendarService.updateTeamEvent(event, with: draft)
            default:
                return
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
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
    
    private func handleDeleteEvent(_ event: Event) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            notificationService.cancelEventReminders(eventId: event.id)
            try await calendarService.deleteTeamEvent(event)
            editorMode = nil
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
    
    private func handleSaveTask() async {
        // This method is no longer used - dismissal is handled directly in the callback
        // Keeping for backwards compatibility but it should not be called
        await MainActor.run {
            editorMode = nil
        }
        await refreshData()
    }
}

enum CalendarEditorMode: Identifiable, Equatable {
    case createEvent(EventDraft)
    case editEvent(Event, EventDraft)
    case createTask
    case editTask(TeamTask)
    
    static func == (lhs: CalendarEditorMode, rhs: CalendarEditorMode) -> Bool {
        switch (lhs, rhs) {
        case (.createEvent(let l), .createEvent(let r)):
            return l.id == r.id
        case (.editEvent(let lEvent, _), .editEvent(let rEvent, _)):
            return lEvent.id == rEvent.id
        case (.createTask, .createTask):
            return true
        case (.editTask(let l), .editTask(let r)):
            return l.id == r.id
        default:
            return false
        }
    }
    
    var id: UUID {
        switch self {
        case .createEvent(let draft):
            return draft.id
        case .editEvent(let event, _):
            return event.id
        case .createTask:
            // Use a stable UUID for createTask to prevent re-presentation issues
            return UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        case .editTask(let task):
            return task.id
        }
    }
}

enum CalendarItem: Identifiable {
    case event(Event)
    case task(TeamTask, dueDate: Date)
    
    var id: UUID {
        switch self {
        case .event(let event):
            return event.id
        case .task(let task, _):
            return task.id
        }
    }
    
    var date: Date {
        switch self {
        case .event(let event):
            return event.startDate
        case .task(_, let dueDate):
            return dueDate
        }
    }
    
    var title: String {
        switch self {
        case .event(let event):
            return event.title
        case .task(let task, _):
            return task.title
        }
    }
    
    var color: Color {
        switch self {
        case .event:
            return DesignSystem.Colors.primary
        case .task:
            return DesignSystem.Colors.accent
        }
    }
    
    var icon: String {
        switch self {
        case .event(let event):
            return event.eventType.icon
        case .task:
            return "checklist"
        }
    }
}

struct CalendarItemRow: View {
    let item: CalendarItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon/Color indicator
                ZStack {
                    Circle()
                        .fill(item.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.icon)
                        .foregroundColor(item.color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Label {
                            Text(item.date, style: .time)
                                .font(.caption)
                        } icon: {
                            Image(systemName: "clock")
                                .font(.caption2)
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        if case .event(let event) = item, let location = event.location, !location.isEmpty {
                            Label {
                                Text(location)
                                    .font(.caption)
                            } icon: {
                                Image(systemName: "mappin")
                                    .font(.caption2)
                            }
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        if case .task(let task, _) = item {
                            Label {
                                Text(task.priority.displayName)
                                    .font(.caption)
                            } icon: {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.caption2)
                            }
                            .foregroundColor(taskPriorityColor(task.priority))
                        }
                    }
                }
                
                Spacer()
                
                // Type badge
                Text(itemTypeLabel)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(item.color.opacity(0.15))
                    .foregroundColor(item.color)
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(item.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var itemTypeLabel: String {
        switch item {
        case .event:
            return "Event"
        case .task:
            return "Task"
        }
    }
    
    private func taskPriorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return DesignSystem.Colors.success
        case .medium:
            return DesignSystem.Colors.warning
        case .high:
            return DesignSystem.Colors.error.opacity(0.8)
        case .urgent:
            return DesignSystem.Colors.error
        }
    }
}

// Calendar-specific Event Editor View
private struct CalendarEventEditorView: View {
    let title: String
    let calendarConnected: Bool
    let notificationsAuthorized: Bool
    var onSave: (EventDraft) -> Void
    var onDelete: (() -> Void)?
    var onCancel: () -> Void
    
    @State private var draft: EventDraft
    
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Event Title", text: $draft.title)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Event Type", selection: $draft.eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("Status", selection: $draft.status) {
                        ForEach(EventStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    TextField("Location (optional)", text: $draft.location)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Details")
                }
                
                Section {
                    DatePicker(
                        "Start",
                        selection: $draft.startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    DatePicker(
                        "End",
                        selection: $draft.endDate,
                        in: draft.startDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text("Timing")
                }
                
                Section {
                    TextEditor(text: $draft.notes)
                        .frame(minHeight: 80)
                } header: {
                    Text("Notes")
                }
                
                Section {
                    if calendarConnected {
                        Toggle("Sync to Calendar", isOn: $draft.syncToCalendar)
                    } else {
                        Label("Calendar sync unavailable", systemImage: "exclamationmark.triangle")
                            .foregroundColor(DesignSystem.Colors.warning)
                            .font(.caption)
                    }
                    
                    if notificationsAuthorized {
                        Toggle("Schedule Reminder", isOn: $draft.scheduleReminder)
                        if draft.scheduleReminder {
                            Stepper(
                                "\(draft.reminderMinutesBefore) minutes before",
                                value: $draft.reminderMinutesBefore,
                                in: 5...120,
                                step: 5
                            )
                        }
                    } else {
                        Label("Notifications unavailable", systemImage: "bell.slash.fill")
                            .foregroundColor(DesignSystem.Colors.warning)
                            .font(.caption)
                    }
                } header: {
                    Text("Options")
                }
                
                if let onDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Text("Delete Event")
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(draft)
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Wrapper Views for Proper Dismissal Handling

private struct CreateTaskViewWrapper: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    let selectedDate: Date
    @Binding var editorMode: CalendarEditorMode?
    @Binding var isDismissing: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        CreateTaskView(selectedDate: selectedDate, onTaskCreated: {
            // Call the dismiss handler which will set isDismissing and clear editorMode
            onDismiss()
        })
        .environmentObject(teamService)
        .environmentObject(authService)
    }
}

private struct TaskDetailViewWrapper: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    let task: TeamTask
    let onDismiss: () -> Void
    
    var body: some View {
        TaskDetailView(task: task)
            .environmentObject(teamService)
            .environmentObject(authService)
    }
}

// MARK: - Custom Calendar with Task Indicators
struct CustomCalendarView: View {
    @Binding var selection: Date
    let tasks: [TeamTask]
    let events: [Event]
    
    @State private var currentMonth: Date = Date()
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    init(selection: Binding<Date>, tasks: [TeamTask], events: [Event]) {
        self._selection = selection
        self.tasks = tasks
        self.events = events
    }
    
    private func hasTasks(for date: Date) -> Bool {
        return tasks.contains { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    private func hasEvents(for date: Date) -> Bool {
        return events.contains { event in
            return calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let firstDayOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start else {
            return []
        }
        
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToSubtract = (firstDayWeekday - calendar.firstWeekday + 7) % 7
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth) else {
            return []
        }
        
        var days: [Date?] = []
        for i in 0..<42 { // 6 weeks * 7 days
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                if calendar.isDate(date, equalTo: firstDayOfMonth, toGranularity: .month) {
                    days.append(date)
                } else if date < firstDayOfMonth || date >= calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) ?? date {
                    days.append(nil) // Outside current month
                } else {
                    days.append(date)
                }
            } else {
                days.append(nil)
            }
        }
        return days
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Month header with navigation
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selection),
                            isToday: calendar.isDateInToday(date),
                            hasTasks: hasTasks(for: date),
                            hasEvents: hasEvents(for: date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        ) {
                            withAnimation {
                                selection = date
                                currentMonth = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTasks: Bool
    let hasEvents: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    init(date: Date, isSelected: Bool, isToday: Bool, hasTasks: Bool, hasEvents: Bool, isCurrentMonth: Bool, action: @escaping () -> Void) {
        self.date = date
        self.isSelected = isSelected
        self.isToday = isToday
        self.hasTasks = hasTasks
        self.hasEvents = hasEvents
        self.isCurrentMonth = isCurrentMonth
        self.action = action
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: hasTasks ? .bold : (isSelected ? .bold : .regular)))
                    .foregroundColor(
                        isSelected ? .white :
                        (isToday ? DesignSystem.Colors.primary :
                         (isCurrentMonth ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary))
                    )
                
                if hasTasks {
                    // Dash indicator for dates with tasks
                    Rectangle()
                        .fill(isSelected ? Color.white.opacity(0.8) : DesignSystem.Colors.primary)
                        .frame(width: 20, height: 2)
                        .cornerRadius(1)
                } else if hasEvents {
                    // Small dot for events
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.6) : DesignSystem.Colors.accent)
                        .frame(width: 4, height: 4)
                } else {
                    Spacer()
                        .frame(height: 2)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        Circle()
                            .fill(DesignSystem.Gradients.primary)
                    } else if isToday {
                        Circle()
                            .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                            .background(Circle().fill(DesignSystem.Colors.primary.opacity(0.1)))
                    } else if hasTasks {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.08))
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    CalendarView()
        .environmentObject(TeamService())
        .environmentObject(SimplifiedCalendarService())
        .environmentObject(NotificationService.shared)
        .environmentObject(AuthService())
}

