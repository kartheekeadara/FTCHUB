//
//  RetentionEngagement.swift
//  FTCHUB
//
//  Lightweight session + streak tracking for welcome-back feedback.
//

import Foundation

enum RetentionEngagement {
    private static let lastActiveDayKey = "ftchub.retention.lastActiveDayStart"
    private static let streakKey = "ftchub.retention.consecutiveActiveDays"
    private static let launchCountKey = "ftchub.retention.appLaunchCount"
    
    /// Increments a simple launch counter (used for soft prompts like notifications).
    static func incrementLaunchCount() {
        let d = UserDefaults.standard
        let n = d.integer(forKey: launchCountKey)
        d.set(n + 1, forKey: launchCountKey)
    }
    
    static var launchCount: Int {
        UserDefaults.standard.integer(forKey: launchCountKey)
    }
    
    /// Call when the main shell appears. Returns a short toast message at most once per calendar day when the user returns after having used the app on a prior day.
    static func takeWelcomeBackToastMessageIfNeeded() -> String? {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let d = UserDefaults.standard
        
        guard let lastStart = d.object(forKey: lastActiveDayKey) as? Date else {
            d.set(todayStart, forKey: lastActiveDayKey)
            return nil
        }
        
        if cal.isDate(lastStart, inSameDayAs: todayStart) {
            return nil
        }
        
        let gapDays = cal.dateComponents([.day], from: lastStart, to: todayStart).day ?? 999
        
        var streak = d.integer(forKey: streakKey)
        if gapDays == 1 {
            streak += 1
        } else {
            streak = 1
        }
        d.set(streak, forKey: streakKey)
        d.set(todayStart, forKey: lastActiveDayKey)
        
        if streak >= 7 {
            return "Amazing — \(streak) days in a row on FTC HUB. Consistency wins championships."
        }
        if streak >= 3 {
            return "Welcome back — \(streak)-day streak. Keep the momentum through build season."
        }
        if gapDays == 1 {
            return "Welcome back — pick up scouting, schedule, or finance where you left off."
        }
        return "Welcome back — your team workspace is ready whenever you are."
    }
}
