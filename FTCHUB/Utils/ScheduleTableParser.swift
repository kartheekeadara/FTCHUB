//
//  ScheduleTableParser.swift
//  FTCHUB
//
//  Created for Schedule Scanning Feature - Phase 2
//  Table structure detection and parsing from OCR text blocks
//

import Foundation
import CoreGraphics

/// Parser for extracting structured match data from OCR text blocks
@MainActor
final class ScheduleTableParser {
    
    // MARK: - Table Structure Detection
    
    /// Detects table structure from text blocks
    /// - Parameter textBlocks: Array of text blocks from OCR
    /// - Returns: Parsed table structure with rows and columns
    static func detectTableStructure(from textBlocks: [TextBlock]) -> TableStructure {
        guard !textBlocks.isEmpty else {
            return TableStructure(rows: [], headerRow: nil)
        }
        
        // Group text blocks into rows
        let rows = ScheduleOCRProcessor.groupIntoRows(textBlocks)
        
        // Detect header row (first row if it contains common header keywords)
        var headerRow: TableRow?
        var dataRows: [TableRow] = []
        
        for (index, rowBlocks) in rows.enumerated() {
            let rowText = rowBlocks.map { $0.text }.joined(separator: " ").lowercased()
            
            // Check if this row contains header keywords
            let headerKeywords = ["match", "time", "red", "blue", "alliance", "team", "qual", "playoff", "field"]
            let isHeader = headerKeywords.contains { rowText.contains($0) }
            
            // More specific check: if row contains both "match" and ("red" or "blue"), it's likely a header
            let hasMatchKeyword = rowText.contains("match")
            let hasAllianceKeywords = rowText.contains("red") || rowText.contains("blue")
            let isLikelyHeader = isHeader || (hasMatchKeyword && hasAllianceKeywords)
            
            if isLikelyHeader && headerRow == nil && index < 3 {
                // Allow header in first 3 rows (in case first row is title)
                headerRow = TableRow(blocks: rowBlocks, rowIndex: index)
            } else {
                dataRows.append(TableRow(blocks: rowBlocks, rowIndex: index))
            }
        }
        
        return TableStructure(rows: dataRows, headerRow: headerRow)
    }
    
    /// Identifies column positions from table structure
    /// - Parameter structure: Table structure
    /// - Returns: Array of column definitions
    static func identifyColumns(from structure: TableStructure) -> [ColumnDefinition] {
        guard !structure.rows.isEmpty else { return [] }
        
        // Analyze first few rows to identify column positions
        let sampleRows = Array(structure.rows.prefix(min(10, structure.rows.count)))
        
        // Collect all X positions
        var xPositions: Set<CGFloat> = []
        for row in sampleRows {
            for block in row.blocks {
                xPositions.insert(block.boundingBox.midX)
            }
        }
        
        let sortedXPositions = Array(xPositions).sorted()
        
        // Cluster nearby X positions to form columns
        var columns: [ColumnDefinition] = []
        let threshold: CGFloat = 80.0 // Maximum distance for same column (increased for better tolerance)
        
        for x in sortedXPositions {
            // Check if this X position is close to an existing column
            if let existingColumnIndex = columns.firstIndex(where: { abs($0.centerX - x) < threshold }) {
                // Update existing column center
                let existing = columns[existingColumnIndex]
                columns[existingColumnIndex] = ColumnDefinition(
                    index: existing.index,
                    centerX: (existing.centerX + x) / 2,
                    width: max(existing.width, abs(existing.centerX - x) * 2)
                )
            } else {
                // Create new column
                columns.append(ColumnDefinition(
                    index: columns.count,
                    centerX: x,
                    width: threshold * 2
                ))
            }
        }
        
        // Sort columns by X position
        columns.sort { $0.centerX < $1.centerX }
        
        // Update indices after sorting
        for (index, _) in columns.enumerated() {
            columns[index] = ColumnDefinition(
                index: index,
                centerX: columns[index].centerX,
                width: columns[index].width
            )
        }
        
        return columns
    }
    
    // MARK: - Match Extraction
    
    /// Extracts match data from table structure
    /// - Parameters:
    ///   - structure: Table structure
    ///   - columns: Column definitions
    ///   - baseDate: Base date for scheduling
    /// - Returns: Array of extracted match data
    static func extractMatches(
        from structure: TableStructure,
        columns: [ColumnDefinition],
        baseDate: Date = Date()
    ) -> [ExtractedMatchData] {
        var matches: [ExtractedMatchData] = []
        
        for row in structure.rows {
            guard let matchData = extractMatchFromRow(row, columns: columns, baseDate: baseDate, headerRow: structure.headerRow) else {
                continue
            }
            matches.append(matchData)
        }
        
        return matches
    }
    
    /// Extracts match data from a single row
    /// - Parameters:
    ///   - row: Table row
    ///   - columns: Column definitions
    ///   - baseDate: Base date for scheduling
    ///   - headerRow: Optional header row for column identification
    /// - Returns: Extracted match data or nil
    private static func extractMatchFromRow(
        _ row: TableRow,
        columns: [ColumnDefinition],
        baseDate: Date,
        headerRow: TableRow? = nil
    ) -> ExtractedMatchData? {
        var matchData = ExtractedMatchData()
        
        // Get text blocks for each column
        var columnTexts: [Int: String] = [:]
        for block in row.blocks {
            // Find which column this block belongs to
            if let columnIndex = findColumnIndex(for: block.boundingBox.midX, in: columns) {
                let existingText = columnTexts[columnIndex] ?? ""
                // Combine text blocks in the same column, preserving all content
                columnTexts[columnIndex] = (existingText + " " + block.text).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                // If block doesn't fit in any column, try to assign it to the nearest column
                if !columns.isEmpty {
                    let nearestColumn = columns.min(by: { abs($0.centerX - block.boundingBox.midX) < abs($1.centerX - block.boundingBox.midX) })
                    if let nearest = nearestColumn, abs(block.boundingBox.midX - nearest.centerX) < nearest.width {
                        let existingText = columnTexts[nearest.index] ?? ""
                        columnTexts[nearest.index] = (existingText + " " + block.text).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        
        // Identify column types from header if available
        var columnTypes: [Int: ColumnType] = [:]
        if let header = headerRow {
            for block in header.blocks {
                if let columnIndex = findColumnIndex(for: block.boundingBox.midX, in: columns) {
                    let headerText = block.text.lowercased()
                    if headerText.contains("match") {
                        columnTypes[columnIndex] = .matchNumber
                    } else if headerText.contains("red") && headerText.contains("1") {
                        columnTypes[columnIndex] = .redTeam1
                    } else if headerText.contains("red") && headerText.contains("2") {
                        columnTypes[columnIndex] = .redTeam2
                    } else if headerText.contains("blue") && headerText.contains("1") {
                        columnTypes[columnIndex] = .blueTeam1
                    } else if headerText.contains("blue") && headerText.contains("2") {
                        columnTypes[columnIndex] = .blueTeam2
                    } else if headerText.contains("time") || headerText.contains("schedule") {
                        columnTypes[columnIndex] = .time
                    } else if headerText.contains("field") {
                        columnTypes[columnIndex] = .field
                    }
                }
            }
        }
        
        // Extract match number (usually first column or identified by header)
        var matchNumberFound = false
        for (index, text) in columnTexts.sorted(by: { $0.key < $1.key }) {
            if let columnType = columnTypes[index], columnType == .matchNumber {
                let matchNumbers = ScheduleOCRProcessor.extractMatchNumbers(from: text)
                if let matchNum = matchNumbers.first {
                    matchData.matchNumber = matchNum
                    matchNumberFound = true
                    break
                }
            } else if !matchNumberFound && index == 0 {
                // Try first column if no header identified it
                let matchNumbers = ScheduleOCRProcessor.extractMatchNumbers(from: text)
                if let matchNum = matchNumbers.first {
                    matchData.matchNumber = matchNum
                    matchNumberFound = true
                }
            }
        }
        
        // Extract time (identified by header or pattern matching)
        for (index, text) in columnTexts {
            if let columnType = columnTypes[index], columnType == .time {
                let times = ScheduleOCRProcessor.extractTimes(from: text)
                if !times.isEmpty {
                    matchData.scheduledTime = times.first
                    break
                }
            } else if matchData.scheduledTime == nil {
                // Try pattern matching if no header
                let times = ScheduleOCRProcessor.extractTimes(from: text)
                if !times.isEmpty {
                    matchData.scheduledTime = times.first
                    break
                }
            }
        }
        
        // Extract team numbers based on column types from header
        for (index, text) in columnTexts {
            if let columnType = columnTypes[index] {
                let teamNumbers = ScheduleOCRProcessor.extractTeamNumbers(from: text)
                // Use all team numbers found in the column, not just the first
                switch columnType {
                case .redTeam1:
                    matchData.redTeam1 = teamNumbers.first
                    // If multiple teams in same column, might be a formatting issue - take first
                case .redTeam2:
                    matchData.redTeam2 = teamNumbers.first
                case .blueTeam1:
                    matchData.blueTeam1 = teamNumbers.first
                case .blueTeam2:
                    matchData.blueTeam2 = teamNumbers.first
                default:
                    break
                }
            }
        }
        
        // If no header was found, use heuristic assignment
        if columnTypes.isEmpty {
            var teamNumbers: [String] = []
            // Collect team numbers from all columns (including first if it doesn't contain match number)
            for (index, text) in columnTexts.sorted(by: { $0.key < $1.key }) {
                // Skip if this column contains a match number
                let hasMatchNumber = ScheduleOCRProcessor.extractMatchNumbers(from: text).isEmpty == false
                if !hasMatchNumber {
                    let numbers = ScheduleOCRProcessor.extractTeamNumbers(from: text)
                    teamNumbers.append(contentsOf: numbers)
                }
            }
            
            // Also check all columns if we didn't find enough teams
            if teamNumbers.count < 4 {
                for (index, text) in columnTexts.sorted(by: { $0.key < $1.key }) {
                    let numbers = ScheduleOCRProcessor.extractTeamNumbers(from: text)
                    // Only add if not already in the list
                    for num in numbers {
                        if !teamNumbers.contains(num) {
                            teamNumbers.append(num)
                        }
                    }
                }
            }
            
            // Assign team numbers to alliances (2 teams per alliance for FTC)
            let teamCount = teamNumbers.count
            if teamCount >= 2 {
                matchData.redTeam1 = teamNumbers.first
                if teamCount > 1 {
                    matchData.redTeam2 = teamNumbers[1]
                }
                if teamCount > 2 {
                    matchData.blueTeam1 = teamNumbers[2]
                }
                if teamCount > 3 {
                    matchData.blueTeam2 = teamNumbers[3]
                }
            }
        }
        
        // Calculate confidence based on available data
        matchData.confidence = calculateConfidence(for: matchData)
        
        // Validate and add warnings
        matchData.warnings = validateMatchData(matchData)
        
        return matchData.isValid ? matchData : nil
    }
    
    /// Column type enumeration for table parsing
    private enum ColumnType {
        case matchNumber
        case time
        case field
        case redTeam1
        case redTeam2
        case blueTeam1
        case blueTeam2
    }
    
    /// Finds the column index for a given X position
    /// - Parameters:
    ///   - x: X position
    ///   - columns: Column definitions
    /// - Returns: Column index or nil
    private static func findColumnIndex(for x: CGFloat, in columns: [ColumnDefinition]) -> Int? {
        for column in columns {
            if abs(x - column.centerX) <= column.width / 2 {
                return column.index
            }
        }
        return nil
    }
    
    // MARK: - Confidence & Validation
    
    /// Calculates confidence score for extracted match data
    /// - Parameter matchData: Extracted match data
    /// - Returns: Confidence score (0.0 - 1.0)
    private static func calculateConfidence(for matchData: ExtractedMatchData) -> Double {
        var score = 0.0
        var factors = 0
        
        if matchData.matchNumber != nil && !matchData.matchNumber!.isEmpty {
            score += 0.3
            factors += 1
        }
        
        if matchData.scheduledTime != nil && !matchData.scheduledTime!.isEmpty {
            score += 0.2
            factors += 1
        }
        
        if matchData.redTeam1 != nil || matchData.blueTeam1 != nil {
            score += 0.3
            factors += 1
        }
        
        if matchData.redTeam2 != nil || matchData.blueTeam2 != nil {
            score += 0.1
            factors += 1
        }
        
        if matchData.isComplete {
            score += 0.1
            factors += 1
        }
        
        return factors > 0 ? min(1.0, score) : 0.0
    }
    
    /// Validates extracted match data and returns warnings
    /// - Parameter matchData: Extracted match data
    /// - Returns: Array of warning messages
    private static func validateMatchData(_ matchData: ExtractedMatchData) -> [String] {
        var warnings: [String] = []
        
        // Validate match number format
        if let matchNumber = matchData.matchNumber {
            if !isValidMatchNumber(matchNumber) {
                warnings.append("Match number format may be incorrect: \(matchNumber)")
            }
        }
        
        // Validate team numbers
        let teamNumbers = [matchData.redTeam1, matchData.redTeam2, matchData.blueTeam1, matchData.blueTeam2].compactMap { $0 }
        for teamNumber in teamNumbers {
            if let num = Int(teamNumber), num < 1 || num > 99999 {
                warnings.append("Team number out of range: \(teamNumber)")
            }
        }
        
        // Check for duplicate teams
        let uniqueTeams = Set(teamNumbers)
        if uniqueTeams.count < teamNumbers.count {
            warnings.append("Duplicate team numbers detected")
        }
        
            // Check for incomplete data (warning removed per user request)
        
        return warnings
    }
    
    /// Validates match number format
    /// - Parameter matchNumber: Match number string
    /// - Returns: True if format is valid
    private static func isValidMatchNumber(_ matchNumber: String) -> Bool {
        // Match numbers should contain letters and numbers
        // Patterns: Q1, Q-1, M1, SF1-1, F1, etc.
        let pattern = #"^[A-Za-z]+-?\d+(?:-\d+)?$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: matchNumber.utf16.count)
        return regex?.firstMatch(in: matchNumber, options: [], range: range) != nil
    }
}

// MARK: - Supporting Types

/// Represents a table structure with rows
struct TableStructure {
    let rows: [TableRow]
    let headerRow: TableRow?
}

/// Represents a single table row
struct TableRow {
    let blocks: [TextBlock]
    let rowIndex: Int
}

/// Represents a column definition
struct ColumnDefinition {
    let index: Int
    let centerX: CGFloat
    let width: CGFloat
}
