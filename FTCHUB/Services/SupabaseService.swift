//
//  SupabaseService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        // Check if we're in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Use mock service for previews
            self.client = MockSupabaseService.shared.client
        } else {
            self.client = SupabaseClient(
                supabaseURL: URL(string: Config.supabaseURL)!,
                supabaseKey: Config.supabaseAnonKey
            )
        }
    }
    
    // MARK: - Database Access
    var database: SupabaseClient {
        return client
    }
    
    // MARK: - Authentication
    var auth: AuthClient {
        return client.auth
    }
    
    // MARK: - Storage
    var storage: SupabaseStorageClient {
        return client.storage
    }
    
    // MARK: - Realtime
    var realtime: RealtimeClientV2 {
        return client.realtimeV2
    }
}
