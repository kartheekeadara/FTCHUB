//
//  TelemetryService.swift
//  FTCHUB
//
//  Created by GPT-5 Codex on 11/8/25.
//

import Foundation
import os.log

@MainActor
final class TelemetryService {
    static let shared = TelemetryService()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ftchub.app", category: "telemetry")
    private let crashLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ftchub.app", category: "crash")
    private var isConfigured = false
    private let telemetryPreferenceKey = "ftchub.telemetryEnabled"
    private let telemetryPreferenceTimestampKey = "ftchub.telemetryPreferenceUpdatedAt"
    
    private init() {}
    
    func configure() {
        guard !isConfigured else { return }
        isConfigured = true
        
        if UserDefaults.standard.object(forKey: telemetryPreferenceKey) == nil {
            UserDefaults.standard.set(true, forKey: telemetryPreferenceKey)
        }
        
        logger.log("Telemetry configured – version: \(self.buildVersion(), privacy: .public)")
    }
    
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: telemetryPreferenceKey) as? Bool ?? true
    }
    
    var lastPreferenceChange: Date? {
        UserDefaults.standard.object(forKey: telemetryPreferenceTimestampKey) as? Date
    }
    
    func updatePreference(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: telemetryPreferenceKey)
        UserDefaults.standard.set(Date(), forKey: telemetryPreferenceTimestampKey)
        logger.log("Telemetry preference updated: \(enabled, privacy: .public)")
    }
    
    func logEvent(_ name: String, parameters: [String: String] = [:]) {
        guard isConfigured, isEnabled else { return }
        if parameters.isEmpty {
            logger.log("Event: \(name, privacy: .public)")
        } else {
            let payload = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logger.log("Event: \(name, privacy: .public) | \(payload, privacy: .public)")
        }
    }
    
    func logError(_ error: Error, context: [String: String] = [:]) {
        guard isConfigured, isEnabled else { return }
        let nsError = error as NSError
        let safeMessage = SecurityUtils.sanitizeForLogging(nsError.localizedDescription)
        if context.isEmpty {
            crashLogger.error("Error: \(safeMessage, privacy: .public)")
        } else {
            let payload = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            crashLogger.error("Error: \(safeMessage, privacy: .public) | \(payload, privacy: .public)")
        }
    }
    
    func logMessage(_ message: String) {
        guard isConfigured, isEnabled else { return }
        logger.log("\(message, privacy: .public)")
    }
    
    private func buildVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }
    
    func handle(exception: NSException) {
        let reason = exception.reason ?? "unknown"
        let symbols = exception.callStackSymbols.joined(separator: "\n")
        crashLogger.fault("Uncaught exception: \(reason, privacy: .public)\n\(symbols, privacy: .public)")
    }
}

