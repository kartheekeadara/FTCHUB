//
//  ExportService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import UIKit
import PDFKit
import UniformTypeIdentifiers
import Supabase

@MainActor
class ExportService: ObservableObject {
    static let shared = ExportService()
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var lastExportDate: Date?
    @Published var exportedFileURL: URL?
    
    private let supabase = SupabaseService.shared.client
    private let localStorage = LocalStorage.shared
    
    private init() {
        // Initialize with default values
        self.isExporting = false
        self.exportProgress = 0.0
        self.errorMessage = nil
    }
    
    // MARK: - File Saving
    func saveToFile(csvData: String, fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
            exportedFileURL = fileURL
            lastExportDate = Date()
            return fileURL
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func savePDFToFile(pdfData: Data, fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            exportedFileURL = fileURL
            lastExportDate = Date()
            return fileURL
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func shareFile(url: URL) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        return activityVC
    }
    
    // MARK: - CSV Export
    func exportInventoryToCSV(items: [InventoryItem]) -> String {
        var csvString = "SKU,Name,Manufacturer,Part Number,Category,Location,Quantity On Hand,Low Stock Threshold,Unit Cost,Description,Created At\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for item in items {
            let row = [
                item.sku,
                escapeCSVField(item.name),
                escapeCSVField(item.manufacturer ?? ""),
                escapeCSVField(item.partNumber ?? ""),
                escapeCSVField(item.category ?? ""),
                escapeCSVField(item.location ?? ""),
                String(item.quantityOnHand),
                String(item.lowStockThreshold),
                item.unitCost?.description ?? "",
                escapeCSVField(item.description ?? ""),
                formatter.string(from: item.createdAt)
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        
        return csvString
    }
    
    func exportScoutingReportsToCSV(reports: [ScoutingReport]) -> String {
        var csvString = "Team Number,Match Number,Event Name,Phase,Scout ID,Notes,Created At"
        
        // Get all unique field names from reports
        let allFieldNames = Set(reports.flatMap { $0.reportData.keys }).sorted()
        csvString += "," + allFieldNames.joined(separator: ",")
        csvString += "\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for report in reports {
            var row = [
                report.scoutedTeamNumber,
                report.matchNumber ?? "",
                report.eventName ?? "",
                report.phase?.rawValue ?? "",
                report.scoutId?.uuidString ?? "",
                escapeCSVField(report.notes ?? ""),
                formatter.string(from: report.createdAt)
            ]
            
            // Add field values in the same order as headers
            for fieldName in allFieldNames {
                row.append(escapeCSVField(report.reportData[fieldName] ?? ""))
            }
            
            csvString += row.joined(separator: ",") + "\n"
        }
        
        return csvString
    }
    
    func exportTeamMembersToCSV(members: [Profile]) -> String {
        var csvString = "First Name,Last Name,Email,Phone,Grade,Role,Member Role,Experience Badges,Emergency Contact Name,Emergency Contact Phone,Created At\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for member in members {
            let badges = member.experienceBadges?.joined(separator: ";") ?? ""
            let row = [
                escapeCSVField(member.firstName ?? ""),
                escapeCSVField(member.lastName ?? ""),
                escapeCSVField(member.email),
                escapeCSVField(member.phone ?? ""),
                member.grade?.description ?? "",
                member.role.rawValue,
                member.memberRole?.rawValue ?? "",
                escapeCSVField(badges),
                escapeCSVField(member.emergencyContactName ?? ""),
                escapeCSVField(member.emergencyContactPhone ?? ""),
                formatter.string(from: member.createdAt)
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        
        return csvString
    }
    
    func exportEventsToCSV(events: [Event]) -> String {
        var csvString = "Title,Description,Start Date,End Date,Location,Event Type,Status,Google Calendar ID,Created At\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for event in events {
            let row = [
                escapeCSVField(event.title),
                escapeCSVField(event.description ?? ""),
                formatter.string(from: event.startDate),
                event.endDate != nil ? formatter.string(from: event.endDate!) : "",
                escapeCSVField(event.location ?? ""),
                event.eventType.rawValue,
                event.status.rawValue,
                escapeCSVField(event.googleCalendarId ?? ""),
                formatter.string(from: event.createdAt)
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        
        return csvString
    }
    
    // MARK: - PDF Export
    func generateTeamReportPDF(team: Team, members: [Profile], events: [Event], inventory: [InventoryItem], scoutingReports: [ScoutingReport]) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "FTC Team Hub",
            kCGPDFContextAuthor: team.name,
            kCGPDFContextTitle: "\(team.displayName) - Team Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Title
            let titleRect = CGRect(x: 50, y: 50, width: pageWidth - 100, height: 50)
            "\(team.displayName) - Team Report".draw(in: titleRect, withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ])
            
            var currentY: CGFloat = 120
            
            // Team Information
            currentY = drawSection(title: "Team Information", content: [
                "Team Name: \(team.name)",
                "Team Number: \(team.number)",
                "Location: \(team.location)",
                "School: \(team.school ?? "N/A")"
            ], startY: currentY, pageWidth: pageWidth)
            
            // Team Members
            currentY = drawSection(title: "Team Members (\(members.count))", content: members.map { member in
                "\(member.displayName) - \(member.memberRole?.displayName ?? "N/A") (\(member.role.displayName))"
            }, startY: currentY, pageWidth: pageWidth)
            
            // Check if we need a new page
            if currentY > pageHeight - 200 {
                context.beginPage()
                currentY = 50
            }
            
            // Upcoming Events
            let upcomingEvents = events.filter { $0.startDate > Date() }.prefix(5)
            currentY = drawSection(title: "Upcoming Events", content: upcomingEvents.map { event in
                "\(event.title) - \(DateFormatter.localizedString(from: event.startDate, dateStyle: .short, timeStyle: .short))"
            }, startY: currentY, pageWidth: pageWidth)
            
            // Inventory Summary
            let lowStockCount = inventory.filter { $0.isLowStock }.count
            let outOfStockCount = inventory.filter { $0.quantityOnHand == 0 }.count
            currentY = drawSection(title: "Inventory Summary", content: [
                "Total Items: \(inventory.count)",
                "Low Stock Items: \(lowStockCount)",
                "Out of Stock Items: \(outOfStockCount)"
            ], startY: currentY, pageWidth: pageWidth)
            
            // Scouting Summary
            let uniqueTeams = Set(scoutingReports.map { $0.scoutedTeamNumber }).count
            currentY = drawSection(title: "Scouting Summary", content: [
                "Total Reports: \(scoutingReports.count)",
                "Teams Scouted: \(uniqueTeams)",
                "Latest Report: \(scoutingReports.first?.createdAt.formatted() ?? "None")"
            ], startY: currentY, pageWidth: pageWidth)
        }
        
        return data
    }
    
    private func drawSection(title: String, content: [String], startY: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var currentY = startY
        
        // Section title
        let titleRect = CGRect(x: 50, y: currentY, width: pageWidth - 100, height: 30)
        title.draw(in: titleRect, withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ])
        
        currentY += 35
        
        // Section content
        for line in content {
            let lineRect = CGRect(x: 70, y: currentY, width: pageWidth - 140, height: 20)
            line.draw(in: lineRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ])
            currentY += 25
        }
        
        return currentY + 20
    }
    
    // MARK: - Backup
    func createBackup() async throws -> Data {
        isExporting = true
        exportProgress = 0.0
        defer { isExporting = false }
        
        do {
            // Collect all data
            exportProgress = 0.1
            
            let teamData = try await loadTeamData()
            exportProgress = 0.3
            
            let inventoryData = try await loadInventoryData()
            exportProgress = 0.5
            
            let scoutingData = try await loadScoutingData()
            exportProgress = 0.7
            
            let eventsData = try await loadEventsData()
            exportProgress = 0.9
            
            // Create backup structure
            let backup = BackupData(
                version: "1.0",
                createdAt: Date(),
                team: teamData.team,
                members: teamData.members,
                events: eventsData,
                inventory: inventoryData,
                scoutingTemplates: scoutingData.templates,
                scoutingReports: scoutingData.reports
            )
            
            let jsonData = try JSONEncoder().encode(backup)
            exportProgress = 1.0
            
            return jsonData
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func restoreBackup(from data: Data) async throws {
        isExporting = true
        exportProgress = 0.0
        defer { isExporting = false }
        
        do {
            let backup = try JSONDecoder().decode(BackupData.self, from: data)
            
            exportProgress = 0.2
            
            // Restore team data
            try await restoreTeamData(backup.team, members: backup.members)
            exportProgress = 0.4
            
            // Restore events
            try await restoreEventsData(backup.events)
            exportProgress = 0.6
            
            // Restore inventory
            try await restoreInventoryData(backup.inventory)
            exportProgress = 0.8
            
            // Restore scouting data
            try await restoreScoutingData(backup.scoutingTemplates, reports: backup.scoutingReports)
            exportProgress = 1.0
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Helper Methods
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
    
    private func loadTeamData() async throws -> (team: Team, members: [Profile]) {
        // Implementation would load from Supabase
        // For now, return empty data
        return (team: Team.sample, members: [])
    }
    
    private func loadInventoryData() async throws -> [InventoryItem] {
        // Implementation would load from Supabase
        return []
    }
    
    private func loadScoutingData() async throws -> (templates: [ScoutingTemplate], reports: [ScoutingReport]) {
        // Implementation would load from Supabase
        return (templates: [], reports: [])
    }
    
    private func loadEventsData() async throws -> [Event] {
        // Implementation would load from Supabase
        return []
    }
    
    private func restoreTeamData(_ team: Team, members: [Profile]) async throws {
        // Implementation would restore to Supabase
    }
    
    private func restoreEventsData(_ events: [Event]) async throws {
        // Implementation would restore to Supabase
    }
    
    private func restoreInventoryData(_ inventory: [InventoryItem]) async throws {
        // Implementation would restore to Supabase
    }
    
    private func restoreScoutingData(_ templates: [ScoutingTemplate], reports: [ScoutingReport]) async throws {
        // Implementation would restore to Supabase
    }
}

// MARK: - Backup Data Model
struct BackupData: Codable {
    let version: String
    let createdAt: Date
    let team: Team
    let members: [Profile]
    let events: [Event]
    let inventory: [InventoryItem]
    let scoutingTemplates: [ScoutingTemplate]
    let scoutingReports: [ScoutingReport]
    
    enum CodingKeys: String, CodingKey {
        case version
        case createdAt = "created_at"
        case team, members, events, inventory
        case scoutingTemplates = "scouting_templates"
        case scoutingReports = "scouting_reports"
    }
}
