//
//  FTCSeasonHelper.swift
//  FTCHUB
//
//  FTC season year helpers (matches FTC Scout convention: Decode = 2025).
//

import Foundation

enum FTCSeasonHelper {
    /// Current FTC season year (FIRST year of the season, e.g. Decode → 2025).
    static var currentSeasonYear: Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        // FTC seasons start in September; before September use previous year as season start.
        return month >= 9 ? year : year - 1
    }

    /// Recent season years to fetch, most recent first.
    static func recentSeasons(count: Int = 4, minimumYear: Int = 2020) -> [Int] {
        let current = currentSeasonYear
        return (0..<count).map { current - $0 }.filter { $0 >= minimumYear }
    }

    static func seasonDisplayName(for year: Int) -> String {
        switch year {
        case 2025: return "Decode"
        case 2024: return "Into the Deep"
        case 2023: return "Centerstage"
        case 2022: return "Power Play"
        case 2021: return "Freight Frenzy"
        case 2020: return "Ultimate Goal"
        case 2019: return "Skystone"
        case 2018: return "Rover Ruckus"
        case 2017: return "Relic Recovery"
        case 2016: return "Velocity Vortex"
        case 2015: return "Res-Q"
        default: return "Season \(year)"
        }
    }

    static func seasonLabel(for year: Int) -> String {
        "\(year): \(seasonDisplayName(for: year))"
    }
}
