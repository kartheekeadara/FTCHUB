//
//  TasksView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @State private var selectedDate = Date()
    @State private var showingCreateTask = false
    @State private var selectedTask: TeamTask?
    @State private var filterMode: TaskFilterMode = .all
    
    private var canCreateTasks: Bool {
        teamService.canCreateTasks
    }
    
    private var tasksForSelectedDate: [TeamTask] {
        let calendar = Calendar.current
        return filteredTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: selectedDate)
        }
        .sorted { task1, task2 in
            guard let date1 = task1.dueDate, let date2 = task2.dueDate else { return false }
            return date1 < date2
        }
    }
    
    private var filteredTasks: [TeamTask] {
        let now = Date()
        switch filterMode {
        case .all:
            return teamService.tasks
        case .today:
            let calendar = Calendar.current
            return teamService.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: now)
            }
        case .thisWeek:
            let calendar = Calendar.current
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? now
            return teamService.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate >= startOfWeek && dueDate < endOfWeek
            }
        case .overdue:
            return teamService.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate < now && task.status != .done
            }
        }
    }
    
    private var tasksForWeek: [TeamTask] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? selectedDate
        
        return filteredTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= startOfWeek && dueDate < endOfWeek
        }
        .sorted { task1, task2 in
            guard let date1 = task1.dueDate, let date2 = task2.dueDate else { return false }
            return date1 < date2
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if teamService.currentTeam == nil {
                    TeamAccessRequiredView(featureName: "Tasks")
                } else {
                    VStack(spacing: 0) {
                        // Date selector header
                        dateSelectorHeader
                        
                        // Timeline view
                        if teamService.isLoading {
                            ProgressView("Loading tasks...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let errorMessage = teamService.errorMessage {
                            errorView(message: errorMessage)
                        } else {
                            timelineContentView
                        }
                    }
                    .background(DesignSystem.Colors.background.ignoresSafeArea())
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if teamService.currentTeam != nil && canCreateTasks {
                        Button(action: {
                            showingCreateTask = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskView(selectedDate: selectedDate)
                    .environmentObject(teamService)
                    .environmentObject(authService)
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task)
                    .environmentObject(teamService)
                    .environmentObject(authService)
            }
            .task {
                if teamService.currentTeam != nil {
                    await teamService.loadTeamData()
                }
            }
            .refreshable {
                if teamService.currentTeam != nil {
                    await teamService.loadTeamData()
                }
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
                        DaySelectorButton(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            taskCount: tasksForDate(date)
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
    
    // MARK: - Timeline Content View
    private var timelineContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if tasksForSelectedDate.isEmpty {
                    emptyStateView
                        .padding(.top, DesignSystem.Spacing.xl * 2)
                } else {
                    // Timeline with tasks
                    TimelineLayoutView(tasks: tasksForSelectedDate, selectedDate: selectedDate) { task in
                        selectedTask = task
                    }
                    .environmentObject(teamService)
                    .environmentObject(authService)
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
            
            Text("No Tasks")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("No tasks scheduled for this day")
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            if canCreateTasks {
                Button {
                    showingCreateTask = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Task")
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
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(DesignSystem.Colors.error)
            
            Text("Error Loading Tasks")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Button("Retry") {
                Task {
                    await teamService.loadTeamData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Properties
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
    
    private func tasksForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        return filteredTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }.count
    }
}

// MARK: - Supporting Types
enum TaskFilterMode: CaseIterable {
    case all, today, thisWeek, overdue
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .overdue: return "Overdue"
        }
    }
}

// MARK: - Day Selector Button
private struct DaySelectorButton: View {
    let date: Date
    let isSelected: Bool
    let taskCount: Int
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
                            } else if taskCount > 0 {
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
                
                if taskCount > 0 {
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

// MARK: - Timeline Layout View
private struct TimelineLayoutView: View {
    let tasks: [TeamTask]
    let selectedDate: Date
    let onTaskTap: (TeamTask) -> Void
    
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    
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
                        TimeMarkerRow(time: timeSlots[index])
                            .frame(height: 60)
                    } else {
                        Spacer()
                            .frame(height: 60)
                    }
                }
            }
            .padding(.leading, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.md)
            
            // Task blocks
            VStack(alignment: .leading, spacing: 0) {
                ForEach(tasks) { task in
                    TimelineTaskBlock(task: task, onTap: onTaskTap)
                        .environmentObject(teamService)
                        .environmentObject(authService)
                }
            }
            .padding(.leading, 100) // Offset for time markers
            .padding(.top, DesignSystem.Spacing.md)
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
}

// MARK: - Time Marker Row
private struct TimeMarkerRow: View {
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

// MARK: - Timeline Task Block
private struct TimelineTaskBlock: View {
    let task: TeamTask
    let onTap: (TeamTask) -> Void
    
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    
    private var taskColor: Color {
        switch task.priority {
        case .urgent: return DesignSystem.Colors.error
        case .high: return DesignSystem.Colors.warning
        case .medium: return DesignSystem.Colors.accent
        case .low: return DesignSystem.Colors.secondary
        }
    }
    
    private var allAssignees: [Profile] {
        task.allAssigneeIds.compactMap { id in
            teamService.teamMembers.first { $0.id == id }
        }
    }
    
    private var taskTimeRange: String {
        guard let dueDate = task.dueDate else { return "No time" }
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let startTime = formatter.string(from: dueDate)
        
        // Default to 1 hour duration if no end time specified
        let endDate = calendar.date(byAdding: .hour, value: 1, to: dueDate) ?? dueDate
        let endTime = formatter.string(from: endDate)
        
        return "\(startTime) - \(endTime)"
    }
    
    private var taskTopOffset: CGFloat {
        guard let dueDate = task.dueDate else { return 0 }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dueDate)
        let minute = calendar.component(.minute, from: dueDate)
        
        // Calculate offset from 6 AM (starting point)
        let startHour = 6
        let totalMinutes = (hour - startHour) * 60 + minute
        let slotHeight: CGFloat = 60 // Height per 30-minute slot
        return CGFloat(totalMinutes / 30) * slotHeight
    }
    
    var body: some View {
        Button(action: { onTap(task) }) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(taskTimeRange)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        if let description = task.description, !description.isEmpty {
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
                if task.status == .done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                taskColor.opacity(0.9),
                                taskColor.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(taskColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: taskColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .offset(y: taskTopOffset)
        .padding(.trailing, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

// MARK: - Create Task View (Redesigned)
struct CreateTaskView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    let selectedDate: Date
    var onTaskCreated: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var selectedAssigneeIds: Set<UUID> = []
    @State private var showingAssigneePicker = false
    @State private var dueDate: Date
    @State private var dueTime: Date
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    init(selectedDate: Date, onTaskCreated: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.selectedDate = selectedDate
        self.onTaskCreated = onTaskCreated
        self.onCancel = onCancel
        let calendar = Calendar.current
        let defaultTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        _dueDate = State(initialValue: selectedDate)
        _dueTime = State(initialValue: defaultTime)
    }
    
    private var combinedDueDate: Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
        return calendar.date(bySettingHour: timeComponents.hour ?? 17, minute: timeComponents.minute ?? 0, second: 0, of: dueDate) ?? dueDate
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: dueTime)
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
                                
                                Text("Team Task")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Priority selector
                            Menu {
                                ForEach(TaskPriority.allCases, id: \.self) { priorityOption in
                                    Button {
                                        priority = priorityOption
                                    } label: {
                                        HStack {
                                            Circle()
                                                .fill(priorityColor(priorityOption))
                                                .frame(width: 12, height: 12)
                                            Text(priorityOption.displayName)
                                            if priority == priorityOption {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(priorityColor(priority))
                                        .frame(width: 10, height: 10)
                                    Text(priority.displayName)
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
                    
                    // Task name
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Task name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("Enter task name", text: $title)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Assigned to
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("Assigned to")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Button {
                                showingAssigneePicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12))
                                    Text("Add")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        
                        if selectedAssigneeIds.isEmpty {
                            Text("Unassigned")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                .padding(DesignSystem.Spacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    ForEach(Array(selectedAssigneeIds), id: \.self) { assigneeId in
                                        if let member = teamService.teamMembers.first(where: { $0.id == assigneeId }) {
                                            AssigneeChip(member: member) {
                                                selectedAssigneeIds.remove(assigneeId)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Due Date & Time
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Due Date & Time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            // Date picker
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
                            
                            // Time picker
                            Button {
                                showingTimePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14))
                                    Text(timeString)
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
                    
                    // Description
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Description")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextEditor(text: $description)
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(minHeight: 100)
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .overlay(
                                Group {
                                    if description.isEmpty {
                                        VStack {
                                            HStack {
                                                Text("Add a description...")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                                    .padding(.leading, DesignSystem.Spacing.md)
                                                    .padding(.top, DesignSystem.Spacing.md)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Create button
                    Button {
                        Task {
                            await createTask()
                        }
                    } label: {
                        Text("Add task")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Gradients.primary)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(title.isEmpty || isCreating)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Add new task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let onCancel = onCancel {
                            onCancel()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAssigneePicker) {
                AssigneePickerView(selectedIds: $selectedAssigneeIds, teamMembers: teamService.teamMembers)
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationStack {
                    Form {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showingTimePicker) {
                NavigationStack {
                    Form {
                        DatePicker("Due Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                    }
                    .navigationTitle("Select Time")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingTimePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(300)])
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
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: dueDate)
    }
    
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return DesignSystem.Colors.error
        case .high: return DesignSystem.Colors.warning
        case .medium: return DesignSystem.Colors.accent
        case .low: return DesignSystem.Colors.secondary
        }
    }
    
    private func createTask() async {
        guard !title.isEmpty else { return }
        guard teamService.currentTeam != nil else {
            errorMessage = "You must be part of a team to create tasks"
            return
        }
        
        guard !isCreating else { return }
        
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }
        
        do {
            let primaryAssignee = selectedAssigneeIds.first
            let additionalAssignees = Array(selectedAssigneeIds.dropFirst())
            
            try await teamService.createTask(
                title: title,
                description: description.isEmpty ? nil : description,
                priority: priority,
                assigneeId: primaryAssignee,
                assigneeIds: additionalAssignees.isEmpty ? nil : additionalAssignees,
                dueDate: combinedDueDate
            )
            
            await MainActor.run {
                dismiss()
            }
            
            onTaskCreated?()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Assignee Chip
private struct AssigneeChip: View {
    let member: Profile
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(member.initials)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(DesignSystem.Colors.primary)
                .clipShape(Circle())
            
            Text(member.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Assignee Picker View (Bottom Sheet)
struct AssigneePickerView: View {
    @Binding var selectedIds: Set<UUID>
    let teamMembers: [Profile]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredMembers: [Profile] {
        if searchText.isEmpty {
            return teamMembers
        } else {
            return teamMembers.filter { member in
                member.displayName.localizedCaseInsensitiveContains(searchText) ||
                member.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    TextField("Name or email", text: $searchText)
                        .textInputAutocapitalization(.never)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.md)
                
                // Recently assigned section
                if !selectedIds.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Recently")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.top, DesignSystem.Spacing.md)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(Array(selectedIds), id: \.self) { id in
                                    if let member = teamMembers.first(where: { $0.id == id }) {
                                        AssigneeChip(member: member) {
                                            selectedIds.remove(id)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                    }
                }
                
                // Members list
                List {
                    ForEach(filteredMembers) { member in
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Text(member.initials)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(DesignSystem.Colors.primary)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text(member.email)
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if selectedIds.contains(member.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedIds.contains(member.id) {
                                selectedIds.remove(member.id)
                            } else {
                                selectedIds.insert(member.id)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Assign to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Task Detail View (keeping existing implementation but will enhance)
struct TaskDetailView: View {
    let task: TeamTask
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var currentTaskStatus: TaskStatus
    
    private var assignee: Profile? {
        guard let assigneeId = task.assigneeId else { return nil }
        return teamService.teamMembers.first { $0.id == assigneeId }
    }
    
    private var allAssignees: [Profile] {
        task.allAssigneeIds.compactMap { id in
            teamService.teamMembers.first { $0.id == id }
        }
    }
    
    private var creator: Profile? {
        teamService.teamMembers.first { $0.id == task.createdBy }
    }
    
    private var canEdit: Bool {
        teamService.canCreateTasks
    }
    
    private var isAssignedToCurrentUser: Bool {
        guard let currentUserId = authService.currentUser?.id else { return false }
        return task.allAssigneeIds.contains(currentUserId)
    }
    
    private var isCurrentUserCoach: Bool {
        guard let currentUserId = authService.currentUser?.id,
              let currentTeam = teamService.currentTeam else { return false }
        
        if currentTeam.coachId == currentUserId { return true }
        if let currentUserProfile = teamService.teamMembers.first(where: { $0.id == currentUserId }),
           currentUserProfile.isCoach || currentUserProfile.memberRole == .coach {
            return true
        }
        return false
    }
    
    private var canCheckOffTask: Bool {
        isAssignedToCurrentUser || isCurrentUserCoach
    }
    
    init(task: TeamTask) {
        self.task = task
        _currentTaskStatus = State(initialValue: task.status)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text(task.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let description = task.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    
                    // Details
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        if allAssignees.isEmpty {
                            TaskDetailRow(icon: "person.fill", label: "Assigned To", value: "Unassigned")
                        } else {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                        .frame(width: 24)
                                    Text("Assigned To")
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Spacer()
                                }
                                
                                ForEach(allAssignees) { assignee in
                                    HStack {
                                        Text(assignee.initials)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(width: 32, height: 32)
                                            .background(DesignSystem.Colors.primary)
                                            .clipShape(Circle())
                                        
                                        Text(assignee.displayName)
                                            .fontWeight(.medium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        
                                        Spacer()
                                    }
                                    .padding(.leading, 32)
                                }
                            }
                        }
                        
                        TaskDetailRow(icon: "clock", label: "Due Date", value: task.dueDate?.formatted(date: .abbreviated, time: .shortened) ?? "No due date")
                        TaskDetailRow(icon: "flag.fill", label: "Priority", value: task.priority.displayName)
                        TaskDetailRow(icon: "checkmark.circle", label: "Status", value: currentTaskStatus.displayName)
                        if let creator = creator {
                            TaskDetailRow(icon: "person.circle", label: "Created By", value: creator.displayName)
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    
                    // Mark as complete/incomplete button
                    if canCheckOffTask {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                currentTaskStatus = currentTaskStatus == .done ? .todo : .done
                            }
                            Task {
                                await toggleTaskStatus()
                            }
                        }) {
                            HStack {
                                Image(systemName: currentTaskStatus == .done ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                Text(currentTaskStatus == .done ? "Mark as Incomplete" : "Mark as Complete")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentTaskStatus == .done ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.success.opacity(0.1))
                            .foregroundColor(currentTaskStatus == .done ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.success)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    if canEdit {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Button(action: {
                                showingEdit = true
                            }) {
                                Label("Edit Task", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(DesignSystem.Colors.primary.opacity(0.1))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                Label("Delete Task", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(DesignSystem.Colors.error.opacity(0.1))
                                    .foregroundColor(DesignSystem.Colors.error)
                                    .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteTask()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
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
            .sheet(isPresented: $showingEdit) {
                EditTaskView(task: task)
                    .environmentObject(teamService)
                    .environmentObject(authService)
            }
        }
    }
    
    private func deleteTask() async {
        isDeleting = true
        do {
            try await teamService.deleteTask(task)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        isDeleting = false
    }
    
    private func toggleTaskStatus() async {
        let updatedTask = TeamTask(
            id: task.id,
            teamId: task.teamId,
            title: task.title,
            description: task.description,
            status: currentTaskStatus,
            priority: task.priority,
            assigneeId: task.assigneeId,
            assigneeIds: task.assigneeIds,
            dueDate: task.dueDate,
            createdBy: task.createdBy,
            createdAt: task.createdAt,
            updatedAt: Date()
        )
        
        do {
            try await teamService.updateTask(updatedTask)
        } catch {
            await MainActor.run {
                currentTaskStatus = task.status
            }
            DebugLog.log("Error updating task status: \(error)")
        }
    }
}

private struct TaskDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24)
            Text(label)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

// MARK: - Edit Task View (keeping existing implementation)
struct EditTaskView: View {
    let task: TeamTask
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    @State private var selectedAssigneeId: UUID?
    @State private var selectedAssigneeIds: Set<UUID>
    @State private var dueDate: Date
    @State private var dueTime: Date
    @State private var status: TaskStatus
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(task: TeamTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _priority = State(initialValue: task.priority)
        _selectedAssigneeId = State(initialValue: task.assigneeId)
        _selectedAssigneeIds = State(initialValue: Set(task.allAssigneeIds))
        _status = State(initialValue: task.status)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _dueTime = State(initialValue: task.dueDate ?? Date())
    }
    
    private var combinedDueDate: Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
        return calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: dueDate) ?? dueDate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Assignment") {
                    NavigationLink {
                        MultipleAssigneeSelectionView(selectedIds: $selectedAssigneeIds, teamMembers: teamService.teamMembers)
                    } label: {
                        HStack {
                            Text("Assign To")
                            Spacer()
                            if selectedAssigneeIds.isEmpty {
                                Text("Unassigned")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            } else {
                                Text("\(selectedAssigneeIds.count) person\(selectedAssigneeIds.count == 1 ? "" : "s")")
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                    }
                    
                    if !selectedAssigneeIds.isEmpty {
                        ForEach(Array(selectedAssigneeIds), id: \.self) { assigneeId in
                            if let member = teamService.teamMembers.first(where: { $0.id == assigneeId }) {
                                HStack {
                                    Text(member.initials)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(DesignSystem.Colors.primary)
                                        .clipShape(Circle())
                                    
                                    Text(member.displayName)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        selectedAssigneeIds.remove(assigneeId)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(priority))
                                    .frame(width: 12, height: 12)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                }
                
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }
                
                Section("Due Date & Time") {
                    DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                    DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveTask()
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
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
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return DesignSystem.Colors.error
        case .high: return DesignSystem.Colors.warning
        case .medium: return DesignSystem.Colors.accent
        case .low: return DesignSystem.Colors.secondary
        }
    }
    
    private func saveTask() async {
        guard !title.isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let primaryAssignee = selectedAssigneeIds.first ?? selectedAssigneeId
            let additionalAssignees = Array(selectedAssigneeIds.dropFirst())
            
            let updatedTask = TeamTask(
                id: task.id,
                teamId: task.teamId,
                title: title,
                description: description.isEmpty ? nil : description,
                status: status,
                priority: priority,
                assigneeId: primaryAssignee,
                assigneeIds: additionalAssignees.isEmpty ? nil : additionalAssignees,
                dueDate: combinedDueDate,
                createdBy: task.createdBy,
                createdAt: task.createdAt,
                updatedAt: Date()
            )
            
            try await teamService.updateTask(updatedTask)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
}

// MARK: - Multiple Assignee Selection View (keeping for EditTaskView)
struct MultipleAssigneeSelectionView: View {
    @Binding var selectedIds: Set<UUID>
    let teamMembers: [Profile]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(teamMembers) { member in
                HStack {
                    Text(member.initials)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(Circle())
                    
                    Text(member.displayName)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if selectedIds.contains(member.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedIds.contains(member.id) {
                        selectedIds.remove(member.id)
                    } else {
                        selectedIds.insert(member.id)
                    }
                }
            }
        }
        .navigationTitle("Select Assignees")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}


#Preview {
    TasksView()
        .environmentObject(TeamService())
        .environmentObject(AuthService())
}

