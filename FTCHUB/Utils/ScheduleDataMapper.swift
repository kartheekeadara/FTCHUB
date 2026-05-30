//
//  ScheduleDataMapper.swift
//  FTCHUB
//
//  Created for Schedule Scanning Feature - Phase 2
//  Data mapping from extracted match data to MatchDraft format
//

import Foundation

/// Maps extracted match data to MatchDraft format for import
@MainActor
final class ScheduleDataMapper {
    
    /// Converts extracted match data to MatchDraft
    /// - Parameters:
    ///   - extractedData: Extracted match data from OCR
    ///   - baseDate: Base date for scheduling (time will be added to this date)
    ///   - defaultAllianceColor: Default alliance color if not detected
    /// - Returns: MatchDraft or nil if data is invalid
    static func mapToMatchDraft(
        from extractedData: ExtractedMatchData,
        baseDate: Date = Date(),
        defaultAllianceColor: AllianceColor = .red
    ) -> MatchDraft? {
        // Validate that we have at least a match number
        guard let matchNumber = extractedData.matchNumber,
              !matchNumber.isEmpty else {
            return nil
        }
        
        // Parse scheduled time
        let scheduledTime = parseScheduledTime(
            extractedData.scheduledTime,
            baseDate: baseDate
        ) ?? baseDate
        
        // Determine alliance color (default to red for now)
        // This could be enhanced to detect from the scan
        let allianceColor = defaultAllianceColor
        
        // Parse team numbers
        let redTeam1 = extractedData.redTeam1.flatMap { Int($0) }
        let redTeam2 = extractedData.redTeam2.flatMap { Int($0) }
        let blueTeam1 = extractedData.blueTeam1.flatMap { Int($0) }
        let blueTeam2 = extractedData.blueTeam2.flatMap { Int($0) }
        
        // Map teams to alliance partners and opponents based on alliance color
        let (alliancePartner1, alliancePartner2, opponent1, opponent2): (Int?, Int?, Int?, Int?)
        
        if allianceColor == .red {
            // Our team is red, partners are red teams, opponents are blue teams
            alliancePartner1 = redTeam1
            alliancePartner2 = redTeam2
            opponent1 = blueTeam1
            opponent2 = blueTeam2
        } else {
            // Our team is blue, partners are blue teams, opponents are red teams
            alliancePartner1 = blueTeam1
            alliancePartner2 = blueTeam2
            opponent1 = redTeam1
            opponent2 = redTeam2
        }
        
        return MatchDraft(
            matchNumber: matchNumber,
            scheduledTime: scheduledTime,
            allianceColor: allianceColor,
            alliancePartner1: alliancePartner1,
            alliancePartner2: alliancePartner2,
            opponent1: opponent1,
            opponent2: opponent2,
            status: .scheduled,
            ourScore: nil,
            opponentScore: nil,
            location: nil
        )
    }
    
    /// Parses scheduled time from string (public helper)
    /// - Parameters:
    ///   - timeString: Time string from OCR (e.g., "10:30 AM", "14:30")
    ///   - baseDate: Base date to add time to
    /// - Returns: Parsed date or nil
    static func parseTimeString(_ timeString: String, baseDate: Date) -> Date? {
        return parseScheduledTime(timeString, baseDate: baseDate)
    }
    
    /// Parses scheduled time from string
    /// - Parameters:
    ///   - timeString: Time string from OCR (e.g., "10:30 AM", "14:30")
    ///   - baseDate: Base date to add time to
    /// - Returns: Parsed date or nil
    private static func parseScheduledTime(_ timeString: String?, baseDate: Date) -> Date? {
        guard let timeString = timeString, !timeString.isEmpty else {
            return nil
        }
        
        let calendar = Calendar.current
        let formatters = [
            createTimeFormatter(format: "h:mm a"),    // 12-hour: "10:30 AM"
            createTimeFormatter(format: "h:mma"),     // 12-hour no space: "10:30AM"
            createTimeFormatter(format: "HH:mm"),     // 24-hour: "14:30"
            createTimeFormatter(format: "HH:mm:ss"),  // 24-hour with seconds: "14:30:00"
            createTimeFormatter(format: "h:mm")       // 12-hour no AM/PM: "10:30"
        ]
        
        for formatter in formatters {
            if let time = formatter.date(from: timeString) {
                let components = calendar.dateComponents([.hour, .minute], from: time)
                return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: baseDate)
            }
        }
        
        return nil
    }
    
    /// Creates a time formatter with the specified format
    /// - Parameter format: Date format string
    /// - Returns: Configured DateFormatter
    private static func createTimeFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    /// Converts multiple extracted match data to MatchDraft array
    /// - Parameters:
    ///   - extractedData: Array of extracted match data
    ///   - baseDate: Base date for scheduling
    ///   - defaultAllianceColor: Default alliance color
    /// - Returns: Array of MatchDraft
    static func mapToMatchDrafts(
        from extractedData: [ExtractedMatchData],
        baseDate: Date = Date(),
        defaultAllianceColor: AllianceColor = .red
    ) -> [MatchDraft] {
        return extractedData.compactMap { data in
            mapToMatchDraft(from: data, baseDate: baseDate, defaultAllianceColor: defaultAllianceColor)
        }
    }
}
