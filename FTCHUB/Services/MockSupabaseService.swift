//
//  MockSupabaseService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

class MockSupabaseService: ObservableObject {
    static let shared = MockSupabaseService()
    
    let client: SupabaseClient
    @Published var objectWillChange = PassthroughSubject<Void, Never>()
    
    private init() {
        // Create a mock client that won't make real network calls
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://mock.supabase.co")!,
            supabaseKey: "mock-key"
        )
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