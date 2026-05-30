//
//  ErrorHandler.swift
//  FTCHUB
//
//  Centralized error handling and user-facing error messages.
//

import Foundation
import SwiftUI

/// Centralized error handling system that converts technical errors into user-friendly messages
struct ErrorHandler {
    
    /// User-friendly error message with recovery suggestions
    struct UserFriendlyError {
        let title: String
        let message: String
        let recoverySuggestion: String?
        let actionTitle: String?
        let action: (() -> Void)?
        
        init(
            title: String,
            message: String,
            recoverySuggestion: String? = nil,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.message = message
            self.recoverySuggestion = recoverySuggestion
            self.actionTitle = actionTitle
            self.action = action
        }
    }
    
    /// Convert any error to a user-friendly error message
    static func userFriendlyError(from error: Error, context: String? = nil) -> UserFriendlyError {
        let errorMessage = error.localizedDescription
        let nsError = error as NSError
        
        // Explicit HTTP 429 (rate limiting)
        if nsError.code == 429 || nsError.domain == "HTTPRateLimit" {
            return UserFriendlyError(
                title: "Too Many Requests",
                message: errorMessage,
                recoverySuggestion: "Wait a moment before trying again.",
                actionTitle: nil
            )
        }
        
        // Network errors
        if let urlError = error as? URLError {
            return handleURLError(urlError, context: context)
        }
        
        // Supabase errors
        if errorMessage.contains("network") || errorMessage.contains("connection") {
            return UserFriendlyError(
                title: "Connection Problem",
                message: "We couldn't connect to the server. Please check your internet connection.",
                recoverySuggestion: "Make sure you're connected to Wi‑Fi or cellular data, then try again.",
                actionTitle: "Retry"
            )
        }
        
        // Authentication errors
        if errorMessage.contains("auth") || errorMessage.contains("authentication") || errorMessage.contains("unauthorized") {
            return UserFriendlyError(
                title: "Sign In Required",
                message: "You need to sign in to access this feature.",
                recoverySuggestion: "Please sign in to your account to continue.",
                actionTitle: "Sign In"
            )
        }
        
        // Permission errors
        if errorMessage.contains("permission") || errorMessage.contains("forbidden") || errorMessage.contains("access denied") {
            return UserFriendlyError(
                title: "Access Denied",
                message: "You don't have permission to perform this action.",
                recoverySuggestion: "Contact your team coach or administrator if you believe this is an error.",
                actionTitle: nil
            )
        }
        
        // Not found errors
        if errorMessage.contains("not found") || errorMessage.contains("404") {
            return UserFriendlyError(
                title: "Not Found",
                message: "The item you're looking for couldn't be found.",
                recoverySuggestion: "It may have been deleted or moved. Try refreshing the page.",
                actionTitle: "Refresh"
            )
        }
        
        // Validation errors
        if errorMessage.contains("invalid") || errorMessage.contains("validation") {
            return UserFriendlyError(
                title: "Invalid Input",
                message: "Please check your input and try again.",
                recoverySuggestion: "Make sure all required fields are filled correctly.",
                actionTitle: nil
            )
        }
        
        // Team-related errors
        if errorMessage.contains("team") {
            if errorMessage.contains("not found") {
                return UserFriendlyError(
                    title: "Team Not Found",
                    message: "The team you're looking for doesn't exist.",
                    recoverySuggestion: "Check the team name or invite code and try again.",
                    actionTitle: nil
                )
            }
            if errorMessage.contains("already") || errorMessage.contains("duplicate") {
                return UserFriendlyError(
                    title: "Already a Member",
                    message: "You're already part of this team.",
                    recoverySuggestion: nil,
                    actionTitle: nil
                )
            }
        }
        
        // Database errors
        if errorMessage.contains("database") || errorMessage.contains("sql") {
            return UserFriendlyError(
                title: "Data Error",
                message: "Something went wrong while saving your data.",
                recoverySuggestion: "Please try again. If the problem persists, contact support.",
                actionTitle: "Retry"
            )
        }
        
        // Rate limiting
        if errorMessage.contains("rate limit") || errorMessage.contains("too many") {
            return UserFriendlyError(
                title: "Too Many Requests",
                message: "You're making requests too quickly. Please wait a moment.",
                recoverySuggestion: "Wait a few seconds and try again.",
                actionTitle: nil
            )
        }
        
        // Generic error with context
        let contextMessage = context != nil ? " (\(context!))" : ""
        return UserFriendlyError(
            title: "Something Went Wrong",
            message: "An unexpected error occurred\(contextMessage).",
            recoverySuggestion: "Please try again. If the problem continues, contact support.",
            actionTitle: "Retry"
        )
    }
    
    /// Handle URL errors specifically
    private static func handleURLError(_ error: URLError, context: String?) -> UserFriendlyError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return UserFriendlyError(
                title: "No Internet Connection",
                message: "You're not connected to the internet.",
                recoverySuggestion: "Check your Wi‑Fi or cellular connection and try again.",
                actionTitle: "Retry"
            )
        case .timedOut:
            return UserFriendlyError(
                title: "Request Timed Out",
                message: "The request took too long to complete.",
                recoverySuggestion: "Your connection might be slow. Please try again.",
                actionTitle: "Retry"
            )
        case .cannotFindHost, .cannotConnectToHost:
            return UserFriendlyError(
                title: "Cannot Reach Server",
                message: "We couldn't reach our servers.",
                recoverySuggestion: "Please check your internet connection and try again.",
                actionTitle: "Retry"
            )
        default:
            return UserFriendlyError(
                title: "Connection Error",
                message: "There was a problem connecting to the server.",
                recoverySuggestion: "Please try again in a moment.",
                actionTitle: "Retry"
            )
        }
    }
    
    /// Log error for debugging (without exposing to user)
    static func logError(_ error: Error, context: String? = nil) {
        #if DEBUG
        let contextMessage = context != nil ? " [\(context!)]" : ""
        print("[Error]\(contextMessage): \(error)")
        if let nsError = error as NSError? {
            print("   Domain: \(nsError.domain)")
            print("   Code: \(nsError.code)")
            print("   UserInfo: \(nsError.userInfo)")
        }
        #endif
    }
}

/// Extension to make ErrorHandler easily accessible
extension Error {
    /// Convert error to user-friendly message
    func userFriendlyMessage(context: String? = nil) -> ErrorHandler.UserFriendlyError {
        ErrorHandler.logError(self, context: context)
        return ErrorHandler.userFriendlyError(from: self, context: context)
    }
}

