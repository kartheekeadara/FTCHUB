//
//  NotificationService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import UserNotifications

@MainActor
class NotificationService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
        // Only check authorization if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            checkAuthorizationStatus()
        } else {
            // Set mock values for previews
            self.isAuthorized = false
            self.pendingNotifications = []
        }
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
    func scheduleEventReminder(for event: Event, minutesBefore: Int = 15) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) starts in \(minutesBefore) minutes"
        content.sound = .default
        content.badge = 1
        
        // Add event data
        content.userInfo = [
            "eventId": event.id.uuidString,
            "eventType": event.eventType.rawValue
        ]
        
        let reminderDate = event.startDate.addingTimeInterval(-TimeInterval(minutesBefore * 60))
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, reminderDate.timeIntervalSinceNow),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "event_\(event.id)_\(minutesBefore)min",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule event reminder: \(error)")
            }
        }
    }
    
    func scheduleMatchReminder(for match: Match, minutesBefore: Int = 10) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Match Starting Soon"
        content.body = "Match \(match.matchNumber) starts in \(minutesBefore) minutes"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "matchId": match.id.uuidString,
            "matchNumber": match.matchNumber
        ]
        
        let reminderDate = match.scheduledTime.addingTimeInterval(-TimeInterval(minutesBefore * 60))
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, reminderDate.timeIntervalSinceNow),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "match_\(match.id)_\(minutesBefore)min",
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
        guard isAuthorized else { return }
        
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
        guard isAuthorized else { return }
        
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
    func scheduleTaskReminder(for task: TeamTask, hoursBefore: Int = 24) {
        guard isAuthorized, let dueDate = task.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = "\(task.title) is due in \(hoursBefore) hours"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "taskId": task.id.uuidString,
            "taskTitle": task.title
        ]
        
        let reminderDate = dueDate.addingTimeInterval(-TimeInterval(hoursBefore * 3600))
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, reminderDate.timeIntervalSinceNow),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "task_\(task.id)_\(hoursBefore)h",
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
    
    // MARK: - Notification Management
    func cancelNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
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
        
        center.setNotificationCategories([eventCategory, inventoryCategory, taskCategory])
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

