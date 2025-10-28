//
//  OfflineIndicator.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct OfflineIndicator: View {
    @EnvironmentObject var offlineService: OfflineService
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main indicator bar
            if !offlineService.isOnline || offlineService.pendingSyncCount > 0 {
                HStack {
                    Image(systemName: offlineService.isOnline ? "arrow.triangle.2.circlepath" : "wifi.slash")
                        .foregroundColor(.white)
                        .animation(.easeInOut(duration: 0.3), value: offlineService.isOnline)
                    
                    Text(offlineService.isOnline ? "Syncing..." : "Offline Mode")
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if offlineService.pendingSyncCount > 0 {
                        HStack(spacing: 4) {
                            Text("\(offlineService.pendingSyncCount)")
                                .foregroundColor(.white)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            
                            Text("pending")
                                .foregroundColor(.white)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(offlineService.isOnline ? Color.orange : Color.red)
                .transition(.move(edge: .top))
                .animation(.easeInOut(duration: 0.3), value: offlineService.isOnline)
            }
            
            // Details sheet
            if showingDetails {
                OfflineDetailsView()
                    .transition(.opacity)
            }
        }
    }
}

struct OfflineDetailsView: View {
    @EnvironmentObject var offlineService: OfflineService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Offline Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    // Close details
                }
                .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(
                    icon: "wifi",
                    title: "Connection",
                    value: offlineService.isOnline ? "Online" : "Offline",
                    color: offlineService.isOnline ? .green : .red
                )
                
                if let storageInfo = offlineService.storageInfo {
                    StatusRow(
                        icon: "internaldrive",
                        title: "Local Storage",
                        value: "\(storageInfo.totalRecords) records",
                        color: .blue
                    )
                    
                    StatusRow(
                        icon: "doc.text",
                        title: "Storage Size",
                        value: ByteCountFormatter.string(fromByteCount: storageInfo.storageSize, countStyle: .file),
                        color: .blue
                    )
                }
                
                StatusRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Pending Sync",
                    value: "\(offlineService.pendingSyncCount) operations",
                    color: offlineService.pendingSyncCount > 0 ? .orange : .green
                )
                
                if let lastSync = offlineService.lastSyncDate {
                    StatusRow(
                        icon: "clock",
                        title: "Last Sync",
                        value: lastSync.formatted(date: .omitted, time: .shortened),
                        color: .gray
                    )
                }
            }
            
            HStack(spacing: 12) {
                Button("Sync Now") {
                    Task {
                        await offlineService.syncNow()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!offlineService.isOnline)
                
                Button("Clear Queue") {
                    offlineService.clearSyncQueue()
                }
                .buttonStyle(.bordered)
                .disabled(offlineService.pendingSyncCount == 0)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack {
        OfflineIndicator()
            .environmentObject(OfflineService())
        
        Spacer()
    }
}
