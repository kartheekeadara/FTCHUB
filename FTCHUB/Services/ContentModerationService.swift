//
//  ContentModerationService.swift
//  FTCHUB
//
//  Created for App Store Compliance - Content Moderation
//

import Foundation
import Supabase
import Combine

@MainActor
class ContentModerationService: ObservableObject {
    static let shared = ContentModerationService()
    
    @Published var blockedUsers: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Report Content
    func reportContent(
        contentType: ContentReport.ContentType,
        contentId: UUID,
        reason: ContentReport.ReportReason,
        description: String?
    ) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw ModerationError.notAuthenticated
        }
        
        let reportInput = try InputValidator.ContentReportInput(description: description)
        let sanitizedDescription = reportInput.description
        
        let report = ContentReport(
            id: UUID(),
            reportedBy: userId,
            contentType: contentType,
            contentId: contentId,
            reason: reason,
            description: sanitizedDescription,
            status: .pending,
            reviewedBy: nil,
            reviewedAt: nil,
            actionTaken: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await supabase
                .from("content_reports")
                .insert(report)
                .execute()
            
            TelemetryService.shared.logEvent("content_reported", parameters: [
                "content_type": contentType.rawValue,
                "reason": reason.rawValue
            ])
        } catch {
            errorMessage = "Failed to submit report: \(error.localizedDescription)"
            TelemetryService.shared.logError(error, context: ["action": "report_content"])
            throw error
        }
    }
    
    // MARK: - Block User
    func blockUser(userId: UUID) async throws {
        guard let currentUserId = supabase.auth.currentUser?.id else {
            throw ModerationError.notAuthenticated
        }
        
        // Store blocked users locally (could also store in database)
        blockedUsers.insert(userId)
        UserDefaults.standard.set(Array(blockedUsers.map { $0.uuidString }), forKey: "blocked_users_\(currentUserId.uuidString)")
        
        TelemetryService.shared.logEvent("user_blocked", parameters: [
            "blocked_user_id": userId.uuidString
        ])
    }
    
    // MARK: - Unblock User
    func unblockUser(userId: UUID) {
        blockedUsers.remove(userId)
        if let currentUserId = supabase.auth.currentUser?.id {
            UserDefaults.standard.set(Array(blockedUsers.map { $0.uuidString }), forKey: "blocked_users_\(currentUserId.uuidString)")
        }
    }
    
    // MARK: - Check if User is Blocked
    func isUserBlocked(_ userId: UUID) -> Bool {
        return blockedUsers.contains(userId)
    }
    
    // MARK: - Filter Content (Basic Profanity Filter)
    func filterContent(_ text: String) -> (filtered: String, hasInappropriateContent: Bool) {
        // Basic profanity filter - in production, use a more sophisticated solution
        // Empty array with explicit type annotation
        let inappropriateWords: [String] = []
        
        // Early return if no words to filter
        if inappropriateWords.isEmpty {
            return (text, false)
        }
        
        var filteredText = text
        var hasInappropriate = false
        
        for word in inappropriateWords {
            if text.localizedCaseInsensitiveContains(word) {
                let replacement = String(repeating: "*", count: word.count)
                filteredText = filteredText.replacingOccurrences(
                    of: word,
                    with: replacement,
                    options: .caseInsensitive
                )
                hasInappropriate = true
            }
        }
        
        return (filteredText, hasInappropriate)
    }
    
    // MARK: - Load Blocked Users
    func loadBlockedUsers() {
        guard let currentUserId = supabase.auth.currentUser?.id else { return }
        
        if let blockedIds = UserDefaults.standard.array(forKey: "blocked_users_\(currentUserId.uuidString)") as? [String] {
            blockedUsers = Set(blockedIds.compactMap { UUID(uuidString: $0) })
        }
    }
}

// MARK: - Moderation Errors
enum ModerationError: LocalizedError {
    case notAuthenticated
    case invalidContent
    case reportFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to report content."
        case .invalidContent:
            return "Invalid content to report."
        case .reportFailed:
            return "Failed to submit report. Please try again."
        }
    }
}

