//
//  HTTPRateLimitHelper.swift
//  FTCHUB
//
//  Shared HTTP 429 detection and retry-after parsing for external APIs.
//

import Foundation

enum HTTPRateLimitHelper {
    
    /// Returns retry delay in seconds from Retry-After header (seconds or HTTP-date).
    static func retryAfterSeconds(from response: HTTPURLResponse) -> Int {
        guard let header = response.value(forHTTPHeaderField: "Retry-After") else {
            return 60
        }
        if let seconds = Int(header), seconds > 0 {
            return seconds
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        if let date = formatter.date(from: header) {
            return max(1, Int(date.timeIntervalSinceNow))
        }
        return 60
    }
    
    static func isRateLimited(_ statusCode: Int) -> Bool {
        statusCode == 429
    }
    
    static func rateLimitError(retryAfter: Int) -> NSError {
        NSError(
            domain: "HTTPRateLimit",
            code: 429,
            userInfo: [
                NSLocalizedDescriptionKey: "Too many requests. Please try again in \(retryAfter) seconds."
            ]
        )
    }
}
