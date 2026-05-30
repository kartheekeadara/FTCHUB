//
//  FinanceExportView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct FinanceExportView: View {
    @EnvironmentObject var financeService: FinanceService
    @EnvironmentObject var exportService: ExportService
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedExportType: ExportType = .orders
    @State private var selectedFormat: ExportFormat = .csv
    @State private var dateRange: DateRange? = nil
    @State private var useDateRange: Bool = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?
    
    enum ExportType: String, CaseIterable {
        case orders = "Orders"
        case budgets = "Budgets"
        case vendors = "Vendors"
        case summary = "Financial Summary"
        
        var icon: String {
            switch self {
            case .orders: return "cart"
            case .budgets: return "chart.pie"
            case .vendors: return "building.2"
            case .summary: return "doc.text"
            }
        }
    }
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
        
        var icon: String {
            switch self {
            case .csv: return "doc.text"
            case .pdf: return "doc.fill"
            }
        }
    }
    
    var filteredOrders: [Order] {
        if let dateRange = dateRange, useDateRange {
            return financeService.orders.filter { dateRange.contains($0.orderDate) }
        }
        return financeService.orders
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Type") {
                    Picker("Type", selection: $selectedExportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    
                    // Date range option for orders
                    if selectedExportType == .orders {
                        Toggle("Use Date Range", isOn: $useDateRange)
                        
                        if useDateRange {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        }
                    }
                }
                
                Section("Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Label(format.rawValue, systemImage: format.icon).tag(format)
                        }
                    }
                    
                    // PDF only available for summary
                    if selectedExportType == .summary && selectedFormat == .pdf {
                        Text("PDF report includes charts and full financial summary")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Records to Export:")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(recordCount)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            .navigationTitle("Export Financial Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportData()
                    }
                    .disabled(exportService.isExporting)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                FinanceShareSheet(activityItems: [url])
            }
        }
        .onChange(of: useDateRange) { oldValue, newValue in
            if newValue {
                dateRange = DateRange(startDate: startDate, endDate: endDate)
            } else {
                dateRange = nil
            }
        }
        .onChange(of: startDate) { oldValue, newValue in
            if useDateRange {
                dateRange = DateRange(startDate: startDate, endDate: endDate)
            }
        }
        .onChange(of: endDate) { oldValue, newValue in
            if useDateRange {
                dateRange = DateRange(startDate: startDate, endDate: endDate)
            }
        }
    }
    
    var recordCount: String {
        switch selectedExportType {
        case .orders:
            return "\(filteredOrders.count) orders"
        case .budgets:
            return "\(financeService.budgets.count) budgets"
        case .vendors:
            return "\(financeService.vendors.count) vendors"
        case .summary:
            return "1 summary report"
        }
    }
    
    private func exportData() {
        errorMessage = nil
        
        Task {
            let url: URL?
            
            switch (selectedExportType, selectedFormat) {
            case (.orders, .csv):
                let csv = exportService.exportOrdersToCSV(orders: filteredOrders)
                let fileName = "orders_\(dateString()).csv"
                url = exportService.saveToFile(csvData: csv, fileName: fileName)
                
            case (.budgets, .csv):
                let csv = exportService.exportBudgetsToCSV(budgets: financeService.budgets)
                let fileName = "budgets_\(dateString()).csv"
                url = exportService.saveToFile(csvData: csv, fileName: fileName)
                
            case (.vendors, .csv):
                let csv = exportService.exportVendorsToCSV(vendors: financeService.vendors)
                let fileName = "vendors_\(dateString()).csv"
                url = exportService.saveToFile(csvData: csv, fileName: fileName)
                
            case (.summary, .pdf):
                let summary = financeService.getFinancialSummary()
                if let pdfData = exportService.generateFinancialSummaryPDF(
                    summary: summary,
                    budgets: financeService.budgets,
                    orders: financeService.orders,
                    vendors: financeService.vendors
                ) {
                    let fileName = "financial_summary_\(dateString()).pdf"
                    url = exportService.savePDFToFile(pdfData: pdfData, fileName: fileName)
                } else {
                    url = nil
                    errorMessage = "Failed to generate PDF"
                }
                
            case (.summary, .csv):
                // CSV summary
                let csv = generateSummaryCSV()
                let fileName = "financial_summary_\(dateString()).csv"
                url = exportService.saveToFile(csvData: csv, fileName: fileName)
                
            default:
                url = nil
                errorMessage = "Format not supported for this export type"
            }
            
            if let url = url {
                exportURL = url
                showingShareSheet = true
            } else if errorMessage == nil {
                errorMessage = "Export failed"
            }
        }
    }
    
    private func generateSummaryCSV() -> String {
        let summary = financeService.getFinancialSummary()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var csv = "Financial Summary Report\n"
        csv += "Generated: \(formatter.string(from: Date()))\n\n"
        csv += "Total Budget,Total Spent,Remaining,Pending,Percentage Used,Order Count,Budget Count,Vendor Count\n"
        csv += "\(summary.totalBudget),\(summary.totalSpent),\(summary.totalRemaining),\(summary.pendingAmount),\(summary.percentageUsed),\(summary.orderCount),\(summary.budgetCount),\(summary.vendorCount)\n"
        
        return csv
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - Share Sheet

struct FinanceShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    FinanceExportView()
        .environmentObject(FinanceService.shared)
        .environmentObject(ExportService.shared)
}

