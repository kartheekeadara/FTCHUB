//
//  ContentView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var offlineService = OfflineService()
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline indicator
            OfflineIndicator()
                .environmentObject(offlineService)
            
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(authService)
                } else {
                    AuthenticationView()
                        .environmentObject(authService)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(OfflineService())
}
