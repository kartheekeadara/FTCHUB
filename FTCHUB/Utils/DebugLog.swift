//
//  DebugLog.swift
//  FTCHUB
//
//  Debug-only logging. Never ships to release builds.
//

import Foundation

enum DebugLog {
    static func log(_ message: @autoclosure () -> String, category: String = "App") {
        #if DEBUG
        print("[\(category)] \(message())")
        #endif
    }
}
