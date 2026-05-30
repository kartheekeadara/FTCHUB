//
//  OfflineIndicator.swift
//  FTCHUB
//

import SwiftUI

/// A slim pill/capsule overlay that slides down from below the status bar.
/// Never paints the status bar background red — uses a dark charcoal capsule instead.
struct OfflineIndicator: View {
    @EnvironmentObject var offlineService: OfflineService
    @State private var showingDetails = false
    @State private var pulsing = false

    private var isVisible: Bool {
        !offlineService.isOnline || offlineService.pendingSyncCount > 0
    }

    var body: some View {
        Group {
            if isVisible {
                Button(action: { showingDetails = true }) {
                    HStack(spacing: 6) {
                        if offlineService.isOnline {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(red: 0.98, green: 0.74, blue: 0.33))
                        } else {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.42, blue: 0.42))
                                .frame(width: 6, height: 6)
                                .opacity(pulsing ? 0.4 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(), value: pulsing)
                        }

                        Text(offlineService.isOnline ? "Syncing…" : "Offline")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(
                                offlineService.isOnline
                                    ? Color(red: 0.98, green: 0.74, blue: 0.33)
                                    : Color(red: 1.0, green: 0.42, blue: 0.42)
                            )

                        if offlineService.pendingSyncCount > 0 {
                            Text("· \(offlineService.pendingSyncCount)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42).opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                offlineService.isOnline
                                    ? Color(red: 0.14, green: 0.11, blue: 0.06)
                                    : Color(red: 0.17, green: 0.10, blue: 0.10)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear { pulsing = !offlineService.isOnline }
                .onChange(of: offlineService.isOnline) { _, online in
                    pulsing = !online
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .sheet(isPresented: $showingDetails) {
            OfflineDetailsSheet()
                .environmentObject(offlineService)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Details sheet (slim, dark themed)

private struct OfflineDetailsSheet: View {
    @EnvironmentObject var offlineService: OfflineService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatusRow(
                        icon: "wifi",
                        title: "Connection",
                        value: offlineService.isOnline ? "Online" : "Offline",
                        color: offlineService.isOnline ? .green : Color(red: 1.0, green: 0.42, blue: 0.42)
                    )
                    StatusRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Pending Sync",
                        value: "\(offlineService.pendingSyncCount) operations",
                        color: offlineService.pendingSyncCount > 0 ? DesignSystem.Colors.primary : DesignSystem.Colors.success
                    )
                    if let lastSync = offlineService.lastSyncDate {
                        StatusRow(
                            icon: "clock",
                            title: "Last Sync",
                            value: lastSync.formatted(date: .omitted, time: .shortened),
                            color: DesignSystem.Colors.textSecondary
                        )
                    }
                    if let storageInfo = offlineService.storageInfo {
                        StatusRow(
                            icon: "internaldrive",
                            title: "Local Records",
                            value: "\(storageInfo.totalRecords)",
                            color: .blue
                        )
                    }
                }

                Section {
                    Button("Sync Now") {
                        Task { await offlineService.syncNow() }
                    }
                    .disabled(!offlineService.isOnline)
                    .foregroundColor(offlineService.isOnline ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)

                    Button("Clear Queue", role: .destructive) {
                        offlineService.clearSyncQueue()
                    }
                    .disabled(offlineService.pendingSyncCount == 0)
                }
            }
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
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
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
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
