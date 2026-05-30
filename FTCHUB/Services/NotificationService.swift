//
//  NotificationService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import UserNotifications
import UIKit

enum NotificationReminderType: String {
    case events
    case matches
    case tasks
    case inventory
}

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var badgeCount: Int = 0
    
    // Notification preferences
    @Published var enableEventReminders = true
    @Published var enableMatchReminders = true
    @Published var enableTaskReminders = true
    @Published var enableInventoryAlerts = true
    @Published var eventReminderMinutes = 15
    @Published var matchReminderMinutes = 10
    @Published var taskReminderHours = 24
    
    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    
    override init() {
        super.init()
        center.delegate = self
        loadPreferences()
        setupNotificationCategories()
        // Only check authorization if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            Task { await refreshAuthorizationStatus() }
        } else {
            // Set mock values for previews
            self.isAuthorized = false
            self.pendingNotifications = []
        }
    }
    
    // MARK: - Preferences
    private func loadPreferences() {
        enableEventReminders = boolPreference(forKey: "enableEventReminders", defaultValue: true)
        enableMatchReminders = boolPreference(forKey: "enableMatchReminders", defaultValue: true)
        enableTaskReminders = boolPreference(forKey: "enableTaskReminders", defaultValue: true)
        enableInventoryAlerts = boolPreference(forKey: "enableInventoryAlerts", defaultValue: true)
        eventReminderMinutes = defaults.integer(forKey: "eventReminderMinutes")
        matchReminderMinutes = defaults.integer(forKey: "matchReminderMinutes")
        taskReminderHours = defaults.integer(forKey: "taskReminderHours")
        
        if eventReminderMinutes == 0 { eventReminderMinutes = 15 }
        if matchReminderMinutes == 0 { matchReminderMinutes = 10 }
        if taskReminderHours == 0 { taskReminderHours = 24 }
    }
    
    private func boolPreference(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
    
    func savePreferences() {
        defaults.set(enableEventReminders, forKey: "enableEventReminders")
        defaults.set(enableMatchReminders, forKey: "enableMatchReminders")
        defaults.set(enableTaskReminders, forKey: "enableTaskReminders")
        defaults.set(enableInventoryAlerts, forKey: "enableInventoryAlerts")
        defaults.set(eventReminderMinutes, forKey: "eventReminderMinutes")
        defaults.set(matchReminderMinutes, forKey: "matchReminderMinutes")
        defaults.set(taskReminderHours, forKey: "taskReminderHours")
    }
    
    // MARK: - Authorization
    var canConfigureReminders: Bool { isAuthorized }
    
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    func requestAuthorization() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            DebugLog.log("Failed to request notification authorization: \(error)")
        }
        await refreshAuthorizationStatus()
    }
    
    func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Cancel / Reschedule Helpers
    
    func cancelEventReminders(eventId: UUID) {
        cancelPending(withPrefix: "event_\(eventId)")
    }
    
    func cancelMatchReminders(matchId: UUID) {
        cancelPending(withPrefix: "match_\(matchId)")
    }
    
    func cancelTaskReminders(taskId: UUID) {
        cancelPending(withPrefix: "task_\(taskId)")
    }
    
    func cancelInventoryAlerts(itemId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "low_stock_\(itemId)",
            "out_of_stock_\(itemId)"
        ])
    }
    
    func cancelAllForType(_ type: NotificationReminderType) async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests.map(\.identifier).filter { identifier in
            switch type {
            case .events: return identifier.hasPrefix("event_")
            case .matches: return identifier.hasPrefix("match_")
            case .tasks: return identifier.hasPrefix("task_")
            case .inventory:
                return identifier.hasPrefix("low_stock_") || identifier.hasPrefix("out_of_stock_")
            }
        }
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        await getPendingNotifications()
    }
    
    func rescheduleEventReminder(for event: Event, minutesBefore: Int? = nil) {
        cancelEventReminders(eventId: event.id)
        scheduleEventReminder(for: event, minutesBefore: minutesBefore)
    }
    
    func rescheduleMatchReminder(for match: Match, minutesBefore: Int? = nil) {
        cancelMatchReminders(matchId: match.id)
        scheduleMatchReminder(for: match, minutesBefore: minutesBefore)
    }
    
    func rescheduleTaskReminder(for task: TeamTask, hoursBefore: Int? = nil) {
        cancelTaskReminders(taskId: task.id)
        scheduleTaskReminder(for: task, hoursBefore: hoursBefore)
    }
    
    func handleInventoryStockChange(from previous: InventoryItem, to updated: InventoryItem) {
        let previousStatus = previous.stockStatus
        let newStatus = updated.stockStatus
        
        if newStatus == .outOfStock, previousStatus != .outOfStock {
            scheduleOutOfStockAlert(for: updated)
        } else if newStatus == .lowStock, previousStatus == .inStock {
            scheduleLowStockAlert(for: updated)
        }
        
        if newStatus == .inStock {
            cancelInventoryAlerts(itemId: updated.id)
        }
    }
    
    private func cancelPending(withPrefix prefix: String) {
        Task {
            let requests = await center.pendingNotificationRequests()
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            guard !ids.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    private func hasPendingNotification(identifier: String) async -> Bool {
        let requests = await center.pendingNotificationRequests()
        return requests.contains { $0.identifier == identifier }
    }
    
    // MARK: - Event Notifications
    func scheduleEventReminder(for event: Event, minutesBefore: Int? = nil) {
        guard isAuthorized, enableEventReminders else { return }
        
        let minutes = minutesBefore ?? eventReminderMinutes
        let reminderDate = event.startDate.addingTimeInterval(-TimeInterval(minutes * 60))
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) starts in \(minutes) minutes"
        content.sound = .default
        content.badge = NSNumber(value: badgeCount + 1)
        content.categoryIdentifier = "EVENT_CATEGORY"
        
        // Add event data
        content.userInfo = [
            "eventId": event.id.uuidString,
            "eventType": event.eventType.rawValue
        ]
        
        cancelEventReminders(eventId: event.id)
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, reminderDate.timeIntervalSinceNow),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "event_\(event.id)_\(minutes)min",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                DebugLog.log("Failed to schedule event reminder: \(error)")
            }
        }
    }
    
    func scheduleMatchReminder(for match: Match, minutesBefore: Int? = nil) {
        guard isAuthorized, enableMatchReminders else { return }
        
        let minutes = minutesBefore ?? matchReminderMinutes
        let reminderDate = match.scheduledTime.addingTimeInterval(-TimeInterval(minutes * 60))
        guard reminderDate > Date() else { return }
        
        cancelMatchReminders(matchId: match.id)
        
        let content = UNMutableNotificationContent()
        content.title = "Match Starting Soon"
        content.body = "Match \(match.matchNumber) starts in \(minutes) minutes"
        content.sound = .default
        content.badge = NSNumber(value: badgeCount + 1)
        content.categoryIdentifier = "MATCH_CATEGORY"
        
        content.userInfo = [
            "matchId": match.id.uuidString,
            "matchNumber": match.matchNumber
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, reminderDate.timeIntervalSinceNow),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "match_\(match.id)_\(minutes)min",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                DebugLog.log("Failed to schedule match reminder: \(error)")
            }
        }
    }
    
    // MARK: - Inventory Notifications
    func scheduleLowStockAlert(for item: InventoryItem) {
        guard isAuthorized, enableInventoryAlerts else { return }
        
        let identifier = "low_stock_\(item.id)"
        Task {
            if await hasPendingNotification(identifier: identifier) { return }
            await addImmediateNotification(
                identifier: identifier,
                title: "Low Stock Alert",
                body: "\(item.name) is running low (\(item.quantityOnHand) remaining)",
                categoryIdentifier: "INVENTORY_CATEGORY",
                userInfo: ["itemId": item.id.uuidString, "itemName": item.name]
            )
        }
    }
    
    private func addImmediateNotification(
        identifier: String,
        title: String,
        body: String,
        categoryIdentifier: String? = nil,
        userInfo: [AnyHashable: Any] = [:]
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        content.userInfo = userInfo
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        try? await center.add(request)
    }
    
    func scheduleLowStockAlertPreview() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alerts Enabled"
        content.body = "We'll let you know when inventory items fall below their thresholds."
        content.sound = .default
        content.categoryIdentifier = "INVENTORY_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "low_stock_preview",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                DebugLog.log("Failed to schedule low stock preview: \(error)")
            }
        }
    }
    
    func scheduleOutOfStockAlert(for item: InventoryItem) {
        guard isAuthorized, enableInventoryAlerts else { return }
        
        let identifier = "out_of_stock_\(item.id)"
        Task {
            if await hasPendingNotification(identifier: identifier) { return }
            await addImmediateNotification(
                identifier: identifier,
                title: "Out of Stock Alert",
                body: "\(item.name) is out of stock",
                categoryIdentifier: "INVENTORY_CATEGORY",
                userInfo: ["itemId": item.id.uuidString, "itemName": item.name]
            )
        }
    }
    
    // MARK: - Task Notifications
    func scheduleTaskReminder(for task: TeamTask, hoursBefore: Int? = nil) {
        guard isAuthorized, enableTaskReminders, let dueDate = task.dueDate else { return }
        
        let hours = hoursBefore ?? taskReminderHours
        let reminderDate = dueDate.addingTimeInterval(-TimeInterval(hours * 3600))
        guard reminderDate > Date() else { return }
        
        cancelTaskReminders(taskId: task.id)
        
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = "\(task.title) is due in \(hours) hours"
        content.sound = .default
        content.badge = NSNumber(value: badgeCount + 1)
        content.categoryIdentifier = "TASK_CATEGORY"
        
        content.userInfo = [
            "taskId": task.id.uuidString,
            "taskTitle": task.title
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, reminderDate.timeIntervalSinceNow),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "task_\(task.id)_\(hours)h",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                DebugLog.log("Failed to schedule task reminder: \(error)")
            }
        }
    }
    
    // MARK: - Grant Deadline Notifications
    func scheduleGrantDeadlineReminder(for grant: Grant, daysBefore: Int = 7) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Grant Deadline Approaching"
        content.body = "\(grant.name) deadline is in \(daysBefore) days"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "grantId": grant.id.uuidString,
            "grantName": grant.name
        ]
        
        let reminderDate = grant.deadline.addingTimeInterval(-TimeInterval(daysBefore * 86400))
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, reminderDate.timeIntervalSinceNow),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "grant_\(grant.id)_\(daysBefore)d",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                DebugLog.log("Failed to schedule grant reminder: \(error)")
            }
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) {
        badgeCount = count
        // Use modern UNUserNotificationCenter API for badge count
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                DebugLog.log("Failed to update badge count: \(error.localizedDescription)")
            }
        }
    }
    
    func incrementBadge() {
        updateBadgeCount(badgeCount + 1)
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Notification Management
    func cancelNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        clearBadge()
    }
    
    func getPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        pendingNotifications = requests
    }
    
    // MARK: - Notification Categories
    func setupNotificationCategories() {
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_CATEGORY",
            actions: [
                UNNotificationAction(identifier: "VIEW_EVENT", title: "View Event", options: [.foreground]),
                UNNotificationAction(identifier: "SNOOZE_EVENT", title: "Snooze 15 min", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let inventoryCategory = UNNotificationCategory(
            identifier: "INVENTORY_CATEGORY",
            actions: [
                UNNotificationAction(identifier: "VIEW_ITEM", title: "View Item", options: [.foreground]),
                UNNotificationAction(identifier: "ORDER_ITEM", title: "Order Now", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_CATEGORY",
            actions: [
                UNNotificationAction(identifier: "VIEW_TASK", title: "View Task", options: [.foreground]),
                UNNotificationAction(identifier: "COMPLETE_TASK", title: "Mark Complete", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let matchCategory = UNNotificationCategory(
            identifier: "MATCH_CATEGORY",
            actions: [
                UNNotificationAction(identifier: "VIEW_MATCH", title: "View Match", options: [.foreground]),
                UNNotificationAction(identifier: "SNOOZE_MATCH", title: "Snooze 5 min", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([eventCategory, inventoryCategory, taskCategory, matchCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            routeNotificationTap(userInfo: userInfo)
            
        case "VIEW_EVENT":
            if let eventId = userInfo["eventId"] as? String {
                NotificationCenter.default.post(
                    name: .ftcOpenEvent,
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            }
            
        case "VIEW_MATCH":
            if let matchId = userInfo["matchId"] as? String {
                NotificationCenter.default.post(
                    name: .ftcOpenMatch,
                    object: nil,
                    userInfo: ["matchId": matchId]
                )
            }
            
        case "VIEW_ITEM", "ORDER_ITEM":
            if let itemId = userInfo["itemId"] as? String {
                NotificationCenter.default.post(
                    name: .ftcOpenInventoryItem,
                    object: nil,
                    userInfo: ["itemId": itemId]
                )
            }
            
        case "VIEW_TASK", "COMPLETE_TASK":
            if let taskId = userInfo["taskId"] as? String {
                NotificationCenter.default.post(
                    name: .ftcOpenTask,
                    object: nil,
                    userInfo: ["taskId": taskId]
                )
            }
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func routeNotificationTap(userInfo: [AnyHashable: Any]) {
        if let eventId = userInfo["eventId"] as? String {
            NotificationCenter.default.post(name: .ftcOpenEvent, object: nil, userInfo: ["eventId": eventId])
        } else if let matchId = userInfo["matchId"] as? String {
            NotificationCenter.default.post(name: .ftcOpenMatch, object: nil, userInfo: ["matchId": matchId])
        } else if let taskId = userInfo["taskId"] as? String {
            NotificationCenter.default.post(name: .ftcOpenTask, object: nil, userInfo: ["taskId": taskId])
        } else if let itemId = userInfo["itemId"] as? String {
            NotificationCenter.default.post(name: .ftcOpenInventoryItem, object: nil, userInfo: ["itemId": itemId])
        }
    }
}

// MARK: - Grant Model
struct Grant: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let deadline: Date
    let amount: Decimal?
    let organization: String
    let requirements: [String]
    let isSubmitted: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, deadline, amount, organization, requirements
        case isSubmitted = "is_submitted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

