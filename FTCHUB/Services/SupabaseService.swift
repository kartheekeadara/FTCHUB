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
            // Security: Validate Supabase URL uses HTTPS
            let urlString = Config.supabaseURL
            guard SecurityUtils.validateSupabaseURL(urlString) else {
                fatalError("Invalid Supabase URL. Must use HTTPS and be a valid Supabase domain.")
            }
            
            guard let url = URL(string: urlString) else {
                fatalError("Invalid Supabase URL format.")
            }
            
            self.client = SupabaseClient(
                supabaseURL: url,
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
