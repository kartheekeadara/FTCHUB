//
//  DeepLinkLogger.swift
//  FTCHUB
//
//  Safe deep-link logging — never logs URL fragments or query strings (may contain tokens).
//

import Foundation

enum DeepLinkLogger {
    static func log(_ message: String) {
        #if DEBUG
        print("[DeepLink] \(message)")
        #endif
    }

    static func logURL(_ url: URL) {
        #if DEBUG
        print("[DeepLink] scheme=\(url.scheme ?? "none") host=\(url.host ?? "none") path=\(url.path)")
        #endif
    }
}
