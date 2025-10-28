//
//  OfflineIndicator.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct OfflineIndicator: View {
    @EnvironmentObject var offlineService: OfflineService
    
    var body: some View {
        if !offlineService.isOnline {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                Text("Offline Mode")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(Color.orange)
        }
    }
}

#Preview {
    OfflineIndicator()
        .environmentObject(OfflineService())
}
