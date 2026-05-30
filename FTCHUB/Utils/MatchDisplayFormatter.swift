//
//  MatchDisplayFormatter.swift
//  FTCHUB
//
//  Consistent match labels for FTC Scout match IDs (quals vs elim brackets).
//

import Foundation

enum MatchDisplayFormatter {
    /// Produces a compact label like Q-12 or M-5 from raw Scout match IDs.
    /// Elim IDs follow the pattern 21001 = series 1, 22001 = series 2, etc.
    static func label(matchId: Int, tournamentLevel: String? = nil, series: Int? = nil) -> String {
        let level = tournamentLevel?.uppercased() ?? ""
        let isQual = level == "QUALS" || level.contains("QUAL")

        if isQual || matchId < 1000 {
            return "Q-\(matchId)"
        }

        if let series, series > 0 {
            return "M-\(series)"
        }

        if matchId >= 21001 {
            let derivedSeries = (matchId / 1000) - 20
            if derivedSeries > 0 {
                return "M-\(derivedSeries)"
            }
        }

        if matchId >= 1000 {
            return "M-\(matchId / 1000)"
        }

        return "Q-\(matchId)"
    }

    /// Recomputes a label when only a legacy display string is available.
    static func normalize(display raw: String, matchId: Int? = nil, tournamentLevel: String? = nil, series: Int? = nil) -> String {
        if let matchId {
            return label(matchId: matchId, tournamentLevel: tournamentLevel, series: series)
        }
        return raw
    }

    /// Splits a label like M-5 or Q-12 into badge-friendly prefix and number.
    static func badgeParts(from label: String) -> (prefix: String, number: String) {
        if let dash = label.firstIndex(of: "-") {
            return (
                String(label[..<dash]),
                String(label[label.index(after: dash)...])
            )
        }
        return ("", label)
    }
}
