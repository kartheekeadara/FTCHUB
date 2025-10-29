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

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
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
            checkAuthorizationStatus()
        } else {
            // Set mock values for previews
            self.isAuthorized = false
            self.pendingNotifications = []
        }
    }
    
    // MARK: - Preferences
    private func loadPreferences() {
        enableEventReminders = defaults.bool(forKey: "enableEventReminders")
        enableMatchReminders = defaults.bool(forKey: "enableMatchReminders")
        enableTaskReminders = defaults.bool(forKey: "enableTaskReminders")
        enableInventoryAlerts = defaults.bool(forKey: "enableInventoryAlerts")
        eventReminderMinutes = defaults.integer(forKey: "eventReminderMinutes")
        matchReminderMinutes = defaults.integer(forKey: "matchReminderMinutes")
        taskReminderHours = defaults.integer(forKey: "taskReminderHours")
        
        // Set defaults if not previously set
        if eventReminderMinutes == 0 { eventReminderMinutes = 15 }
        if matchReminderMinutes == 0 { matchReminderMinutes = 10 }
        if taskReminderHours == 0 { taskReminderHours = 24 }
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
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Event Notifications
    func scheduleEventReminder(for event: Event, minutesBefore: Int? = nil) {
        guard isAuthorized, enableEventReminders else { return }
        
        let minutes = minutesBefore ?? eventReminderMinutes
        
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
        
        let reminderDate = event.startDate.addingTimeInterval(-TimeInterval(minutes * 60))
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
                print("Failed to schedule event reminder: \(error)")
            }
        }
    }
    
    func scheduleMatchReminder(for match: Match, minutesBefore: Int? = nil) {
        guard isAuthorized, enableMatchReminders else { return }
        
        let minutes = minutesBefore ?? matchReminderMinutes
        
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
        
        let reminderDate = match.scheduledTime.addingTimeInterval(-TimeInterval(minutes * 60))
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
                print("Failed to schedule match reminder: \(error)")
            }
        }
    }
    
    // MARK: - Inventory Notifications
    func scheduleLowStockAlert(for item: InventoryItem) {
        guard isAuthorized, enableInventoryAlerts else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "\(item.name) is running low (\(item.quantityOnHand) remaining)"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "itemId": item.id.uuidString,
            "itemName": item.name
        ]
        
        let request = UNNotificationRequest(
            identifier: "low_stock_\(item.id)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule low stock alert: \(error)")
            }
        }
    }
    
    func scheduleOutOfStockAlert(for item: InventoryItem) {
        guard isAuthorized, enableInventoryAlerts else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Out of Stock Alert"
        content.body = "\(item.name) is out of stock"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "itemId": item.id.uuidString,
            "itemName": item.name
        ]
        
        let request = UNNotificationRequest(
            identifier: "out_of_stock_\(item.id)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule out of stock alert: \(error)")
            }
        }
    }
    
    // MARK: - Task Notifications
    func scheduleTaskReminder(for task: TeamTask, hoursBefore: Int? = nil) {
        guard isAuthorized, enableTaskReminders, let dueDate = task.dueDate else { return }
        
        let hours = hoursBefore ?? taskReminderHours
        
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
        
        let reminderDate = dueDate.addingTimeInterval(-TimeInterval(hours * 3600))
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
                print("Failed to schedule task reminder: \(error)")
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
                print("Failed to schedule grant reminder: \(error)")
            }
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) {
        badgeCount = count
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = count
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
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "VIEW_EVENT":
            if let eventId = userInfo["eventId"] as? String {
                // Navigate to event detail
                print("Navigate to event: \(eventId)")
            }
            
        case "VIEW_ITEM":
            if let itemId = userInfo["itemId"] as? String {
                // Navigate to inventory item
                print("Navigate to item: \(itemId)")
            }
            
        case "VIEW_TASK":
            if let taskId = userInfo["taskId"] as? String {
                // Navigate to task detail
                print("Navigate to task: \(taskId)")
            }
            
        case "ORDER_ITEM":
            if let itemId = userInfo["itemId"] as? String {
                // Navigate to order form
                print("Order item: \(itemId)")
            }
            
        case "COMPLETE_TASK":
            if let taskId = userInfo["taskId"] as? String {
                // Mark task as complete
                print("Complete task: \(taskId)")
            }
            
        default:
            break
        }
        
        completionHandler()
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

