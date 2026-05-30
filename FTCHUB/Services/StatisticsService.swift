//
//  StatisticsService.swift
//  FTCHUB
//
//  Phase 1: Core Statistics Engine
//  Implements OPR, DPR, and CCWM calculations using linear algebra
//

import Foundation
import Combine
import Supabase

@MainActor
class StatisticsService: ObservableObject {
    static let shared = StatisticsService()
    
    @Published var statistics: [TeamStatistics] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Data Models
    
    struct TeamStatistics: Codable, Identifiable {
        let id: UUID
        let teamNumber: String
        let eventName: String?
        let seasonYear: Int?
        let opr: Double?
        let dpr: Double?
        let ccwm: Double?
        let matchesPlayed: Int
        let wins: Int
        let losses: Int
        let ties: Int
        let averageScore: Double?
        let averageAllianceScore: Double?
        let averageOpponentScore: Double?
        let highestScore: Int?
        let lowestScore: Int?
        let averageAutoScore: Double?
        let averageTeleopScore: Double?
        let averageEndgameScore: Double?
        let winRate: Double?
        let consistencyScore: Double?
        let oprRank: Int?
        let ccwmRank: Int?
        let winRateRank: Int?
        let lastCalculatedAt: Date
        let calculationMethod: String
        let matchesUsed: Int?
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamNumber = "team_number"
            case eventName = "event_name"
            case seasonYear = "season_year"
            case opr, dpr, ccwm
            case matchesPlayed = "matches_played"
            case wins, losses, ties
            case averageScore = "average_score"
            case averageAllianceScore = "average_alliance_score"
            case averageOpponentScore = "average_opponent_score"
            case highestScore = "highest_score"
            case lowestScore = "lowest_score"
            case averageAutoScore = "average_auto_score"
            case averageTeleopScore = "average_teleop_score"
            case averageEndgameScore = "average_endgame_score"
            case winRate = "win_rate"
            case consistencyScore = "consistency_score"
            case oprRank = "opr_rank"
            case ccwmRank = "ccwm_rank"
            case winRateRank = "win_rate_rank"
            case lastCalculatedAt = "last_calculated_at"
            case calculationMethod = "calculation_method"
            case matchesUsed = "matches_used"
        }
    }
    
    enum StatisticMetric: String {
        case opr
        case dpr
        case ccwm
        case winRate
    }
    
    // MARK: - Matrix Operations Helper
    
    private struct MatrixOperations {
        /// Solves the linear system A * x = b using least squares method (normal equations)
        /// Uses normal equations: (A^T * A) * x = A^T * b
        /// Returns the solution vector x
        static func solveLeastSquares(A: [[Double]], b: [Double]) throws -> [Double] {
            let m = A.count // number of equations
            let n = A[0].count // number of unknowns
            
            guard m >= n else {
                throw StatisticsError.insufficientData("Need at least \(n) matches for \(n) teams")
            }
            
            // Compute A^T (transpose)
            let AT = transpose(A)
            
            // Compute A^T * A
            let ATA = multiply(AT, A)
            
            // Compute A^T * b
            let ATb = multiplyVector(AT, b)
            
            // Solve (A^T * A) * x = A^T * b using Gaussian elimination
            return try solveLinearSystem(A: ATA, b: ATb)
        }
        
        /// Solves a linear system A * x = b using Gaussian elimination with partial pivoting
        static func solveLinearSystem(A: [[Double]], b: [Double]) throws -> [Double] {
            let n = A.count
            guard n == b.count && n > 0 else {
                throw StatisticsError.calculationFailed("Matrix dimensions don't match")
            }
            
            // Create augmented matrix [A | b]
            var augmented = A.enumerated().map { (index, row) in
                row + [b[index]]
            }
            
            // Forward elimination with partial pivoting
            for i in 0..<n {
                // Find pivot (largest element in column)
                var maxRow = i
                var maxVal = abs(augmented[i][i])
                for k in (i+1)..<n {
                    if abs(augmented[k][i]) > maxVal {
                        maxVal = abs(augmented[k][i])
                        maxRow = k
                    }
                }
                
                // Swap rows if needed
                if maxRow != i {
                    augmented.swapAt(i, maxRow)
                }
                
                // Check for singular matrix
                guard abs(augmented[i][i]) > 1e-10 else {
                    throw StatisticsError.calculationFailed("Matrix is singular or near-singular")
                }
                
                // Eliminate column below pivot
                for k in (i+1)..<n {
                    let factor = augmented[k][i] / augmented[i][i]
                    for j in i..<(n+1) {
                        augmented[k][j] -= factor * augmented[i][j]
                    }
                }
            }
            
            // Back substitution
            var x = Array(repeating: 0.0, count: n)
            for i in stride(from: n-1, through: 0, by: -1) {
                x[i] = augmented[i][n]
                for j in (i+1)..<n {
                    x[i] -= augmented[i][j] * x[j]
                }
                x[i] /= augmented[i][i]
            }
            
            return x
        }
        
        /// Multiplies a matrix by a vector: A * v
        static func multiplyVector(_ A: [[Double]], _ v: [Double]) -> [Double] {
            return A.map { row in
                zip(row, v).map(*).reduce(0, +)
            }
        }
        
        /// Calculates matrix transpose
        static func transpose(_ matrix: [[Double]]) -> [[Double]] {
            guard !matrix.isEmpty else { return [] }
            let rows = matrix.count
            let cols = matrix[0].count
            
            return (0..<cols).map { col in
                (0..<rows).map { row in
                    matrix[row][col]
                }
            }
        }
        
        /// Multiplies two matrices: C = A * B
        static func multiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
            let rowsA = A.count
            let colsA = A[0].count
            let colsB = B[0].count
            
            var result = Array(repeating: Array(repeating: 0.0, count: colsB), count: rowsA)
            
            for i in 0..<rowsA {
                for j in 0..<colsB {
                    var sum = 0.0
                    for k in 0..<colsA {
                        sum += A[i][k] * B[k][j]
                    }
                    result[i][j] = sum
                }
            }
            
            return result
        }
    }
    
    // MARK: - Statistics Calculation
    
    /// Calculates OPR (Offensive Power Rating) for all teams in an event
    func calculateOPR(matches: [Match], teams: [String], eventName: String) async throws -> [String: Double] {
        guard matches.count >= teams.count else {
            throw StatisticsError.insufficientData("Need at least \(teams.count) matches for \(teams.count) teams")
        }
        
        // Build coefficient matrix A and result vector b
        var A: [[Double]] = []
        var b: [Double] = []
        
        // Create team index mapping
        let teamIndexMap = Dictionary(uniqueKeysWithValues: teams.enumerated().map { ($0.element, $0.offset) })
        
        for match in matches {
            // Skip incomplete or forfeited matches
            guard match.status == .completed,
                  let redScore = match.redAllianceScore ?? (match.allianceColor == .red ? match.ourScore : match.opponentScore),
                  let blueScore = match.blueAllianceScore ?? (match.allianceColor == .blue ? match.ourScore : match.opponentScore) else {
                continue
            }
            
            // Get team numbers for red alliance
            let redTeams = getRedAllianceTeams(from: match)
            let blueTeams = getBlueAllianceTeams(from: match)
            
            guard redTeams.count == 3, blueTeams.count == 3 else {
                continue
            }
            
            // Create row for red alliance
            var redRow = Array(repeating: 0.0, count: teams.count)
            for team in redTeams {
                if let index = teamIndexMap[team] {
                    redRow[index] = 1.0
                }
            }
            A.append(redRow)
            b.append(Double(redScore))
            
            // Create row for blue alliance
            var blueRow = Array(repeating: 0.0, count: teams.count)
            for team in blueTeams {
                if let index = teamIndexMap[team] {
                    blueRow[index] = 1.0
                }
            }
            A.append(blueRow)
            b.append(Double(blueScore))
        }
        
        guard A.count >= teams.count else {
            throw StatisticsError.insufficientData("Not enough valid matches for calculation")
        }
        
        // Solve the system
        let solution = try MatrixOperations.solveLeastSquares(A: A, b: b)
        
        // Map solution back to team numbers
        var oprMap: [String: Double] = [:]
        for (index, team) in teams.enumerated() {
            if index < solution.count {
                oprMap[team] = solution[index]
            }
        }
        
        return oprMap
    }
    
    /// Calculates DPR (Defensive Power Rating) for all teams
    func calculateDPR(matches: [Match], teams: [String], eventName: String) async throws -> [String: Double] {
        // DPR is calculated the same way as OPR, but using opponent scores
        guard matches.count >= teams.count else {
            throw StatisticsError.insufficientData("Need at least \(teams.count) matches for \(teams.count) teams")
        }
        
        var A: [[Double]] = []
        var b: [Double] = []
        
        let teamIndexMap = Dictionary(uniqueKeysWithValues: teams.enumerated().map { ($0.element, $0.offset) })
        
        for match in matches {
            guard match.status == .completed,
                  let redScore = match.redAllianceScore ?? (match.allianceColor == .red ? match.ourScore : match.opponentScore),
                  let blueScore = match.blueAllianceScore ?? (match.allianceColor == .blue ? match.ourScore : match.opponentScore) else {
                continue
            }
            
            let redTeams = getRedAllianceTeams(from: match)
            let blueTeams = getBlueAllianceTeams(from: match)
            
            guard redTeams.count == 3, blueTeams.count == 3 else {
                continue
            }
            
            // For DPR, we use opponent scores
            // Red alliance's DPR = blue alliance's score
            var redRow = Array(repeating: 0.0, count: teams.count)
            for team in redTeams {
                if let index = teamIndexMap[team] {
                    redRow[index] = 1.0
                }
            }
            A.append(redRow)
            b.append(Double(blueScore)) // Opponent score
            
            var blueRow = Array(repeating: 0.0, count: teams.count)
            for team in blueTeams {
                if let index = teamIndexMap[team] {
                    blueRow[index] = 1.0
                }
            }
            A.append(blueRow)
            b.append(Double(redScore)) // Opponent score
        }
        
        guard A.count >= teams.count else {
            throw StatisticsError.insufficientData("Not enough valid matches for calculation")
        }
        
        let solution = try MatrixOperations.solveLeastSquares(A: A, b: b)
        
        var dprMap: [String: Double] = [:]
        for (index, team) in teams.enumerated() {
            if index < solution.count {
                dprMap[team] = solution[index]
            }
        }
        
        return dprMap
    }
    
    /// Calculates CCWM (Calculated Contribution to Winning Margin)
    func calculateCCWM(opr: [String: Double], dpr: [String: Double]) -> [String: Double] {
        var ccwmMap: [String: Double] = [:]
        
        for team in opr.keys {
            let teamOPR = opr[team] ?? 0.0
            let teamDPR = dpr[team] ?? 0.0
            ccwmMap[team] = teamOPR - teamDPR
        }
        
        return ccwmMap
    }
    
    // MARK: - Helper Methods
    
    private func getRedAllianceTeams(from match: Match) -> [String] {
        var teams: [String] = []
        
        // Try to get from new columns first
        if let team1 = match.redTeam1 { teams.append(team1) }
        if let team2 = match.redTeam2 { teams.append(team2) }
        if let team3 = match.redTeam3 { teams.append(team3) }
        
        // Fallback to old columns if new ones aren't available
        if teams.isEmpty {
            if match.allianceColor == .red {
                if let partner1 = match.alliancePartner1 {
                    teams.append(String(partner1))
                }
                if let partner2 = match.alliancePartner2 {
                    teams.append(String(partner2))
                }
                // Our team number would need to come from team_id lookup
            }
        }
        
        return teams
    }
    
    private func getBlueAllianceTeams(from match: Match) -> [String] {
        var teams: [String] = []
        
        // Try to get from new columns first
        if let team1 = match.blueTeam1 { teams.append(team1) }
        if let team2 = match.blueTeam2 { teams.append(team2) }
        if let team3 = match.blueTeam3 { teams.append(team3) }
        
        // Fallback to old columns
        if teams.isEmpty {
            if match.allianceColor == .blue {
                if let partner1 = match.alliancePartner1 {
                    teams.append(String(partner1))
                }
                if let partner2 = match.alliancePartner2 {
                    teams.append(String(partner2))
                }
            } else {
                // If we're red, opponents are blue
                if let opp1 = match.opponent1 {
                    teams.append(String(opp1))
                }
                if let opp2 = match.opponent2 {
                    teams.append(String(opp2))
                }
                if let opp3 = match.opponent3 {
                    teams.append(String(opp3))
                }
            }
        }
        
        return teams
    }
    
    // MARK: - Database Operations
    
    /// Calculates and saves statistics for an event
    func calculateStatisticsForEvent(eventName: String, seasonYear: Int? = nil) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Load all matches for the event
            var query = supabase
                .from("matches")
                .select()
                .eq("event_name", value: eventName)
            
            if let seasonYear = seasonYear {
                query = query.eq("season_year", value: seasonYear)
            }
            
            let matches: [Match] = try await query
                .execute()
                .value
            
            guard !matches.isEmpty else {
                throw StatisticsError.insufficientData("No matches found for event: \(eventName)")
            }
            
            // Get unique team numbers from matches
            var teamSet = Set<String>()
            for match in matches {
                teamSet.formUnion(getRedAllianceTeams(from: match))
                teamSet.formUnion(getBlueAllianceTeams(from: match))
            }
            let teams = Array(teamSet).sorted()
            
            guard teams.count >= 3 else {
                throw StatisticsError.insufficientData("Need at least 3 teams for statistics calculation")
            }
            
            // Calculate OPR and DPR
            let opr = try await calculateOPR(matches: matches, teams: teams, eventName: eventName)
            let dpr = try await calculateDPR(matches: matches, teams: teams, eventName: eventName)
            let ccwm = calculateCCWM(opr: opr, dpr: dpr)
            
            // Calculate additional statistics for each team
            var statisticsToSave: [TeamStatistics] = []
            
            for team in teams {
                let teamMatches = matches.filter { match in
                    getRedAllianceTeams(from: match).contains(team) ||
                    getBlueAllianceTeams(from: match).contains(team)
                }
                
                let stats = calculateTeamStatistics(
                    teamNumber: team,
                    matches: teamMatches,
                    opr: opr[team],
                    dpr: dpr[team],
                    ccwm: ccwm[team],
                    eventName: eventName,
                    seasonYear: seasonYear
                )
                
                statisticsToSave.append(stats)
            }
            
            // Calculate rankings
            let rankedStats = calculateRankings(statisticsToSave)
            
            // Save to database
            try await saveStatistics(rankedStats)
            
            // Update published property
            statistics = rankedStats
            
        } catch {
            errorMessage = "Failed to calculate statistics: \(error.localizedDescription)"
            throw error
        }
    }
    
    private func calculateTeamStatistics(
        teamNumber: String,
        matches: [Match],
        opr: Double?,
        dpr: Double?,
        ccwm: Double?,
        eventName: String,
        seasonYear: Int?
    ) -> TeamStatistics {
        let completedMatches = matches.filter { $0.status == .completed }
        let matchesPlayed = completedMatches.count
        
        var wins = 0
        var losses = 0
        var ties = 0
        
        var scores: [Int] = []
        var allianceScores: [Int] = []
        var opponentScores: [Int] = []
        
        for match in completedMatches {
            let isRed = getRedAllianceTeams(from: match).contains(teamNumber)
            let redScore = match.redAllianceScore ?? (match.allianceColor == .red ? match.ourScore : match.opponentScore) ?? 0
            let blueScore = match.blueAllianceScore ?? (match.allianceColor == .blue ? match.ourScore : match.opponentScore) ?? 0
            
            if isRed {
                allianceScores.append(redScore)
                opponentScores.append(blueScore)
                if redScore > blueScore { wins += 1 }
                else if redScore < blueScore { losses += 1 }
                else { ties += 1 }
            } else {
                allianceScores.append(blueScore)
                opponentScores.append(redScore)
                if blueScore > redScore { wins += 1 }
                else if blueScore < redScore { losses += 1 }
                else { ties += 1 }
            }
            
            scores.append(isRed ? redScore : blueScore)
        }
        
        let winRate = matchesPlayed > 0 ? Double(wins) / Double(matchesPlayed) : nil
        let averageScore = scores.isEmpty ? nil : Double(scores.reduce(0, +)) / Double(scores.count)
        let averageAllianceScore = allianceScores.isEmpty ? nil : Double(allianceScores.reduce(0, +)) / Double(allianceScores.count)
        let averageOpponentScore = opponentScores.isEmpty ? nil : Double(opponentScores.reduce(0, +)) / Double(opponentScores.count)
        
        // Calculate consistency (standard deviation of scores)
        let consistencyScore: Double? = {
            guard scores.count > 1 else { return nil }
            let mean = averageScore ?? 0.0
            let variance = scores.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(scores.count)
            return sqrt(variance)
        }()
        
        return TeamStatistics(
            id: UUID(),
            teamNumber: teamNumber,
            eventName: eventName,
            seasonYear: seasonYear,
            opr: opr,
            dpr: dpr,
            ccwm: ccwm,
            matchesPlayed: matchesPlayed,
            wins: wins,
            losses: losses,
            ties: ties,
            averageScore: averageScore,
            averageAllianceScore: averageAllianceScore,
            averageOpponentScore: averageOpponentScore,
            highestScore: scores.max(),
            lowestScore: scores.min(),
            averageAutoScore: nil, // TODO: Calculate from phase data
            averageTeleopScore: nil, // TODO: Calculate from phase data
            averageEndgameScore: nil, // TODO: Calculate from phase data
            winRate: winRate,
            consistencyScore: consistencyScore,
            oprRank: nil, // Set in calculateRankings
            ccwmRank: nil, // Set in calculateRankings
            winRateRank: nil, // Set in calculateRankings
            lastCalculatedAt: Date(),
            calculationMethod: "linear_algebra",
            matchesUsed: matchesPlayed
        )
    }
    
    private func calculateRankings(_ stats: [TeamStatistics]) -> [TeamStatistics] {
        // Sort by OPR, CCWM, and Win Rate, then assign ranks
        let sortedByOPR = stats.sorted { ($0.opr ?? -Double.infinity) > ($1.opr ?? -Double.infinity) }
        let sortedByCCWM = stats.sorted { ($0.ccwm ?? -Double.infinity) > ($1.ccwm ?? -Double.infinity) }
        let sortedByWinRate = stats.sorted { ($0.winRate ?? -Double.infinity) > ($1.winRate ?? -Double.infinity) }
        
        var rankedStats = stats
        
        for (index, stat) in sortedByOPR.enumerated() {
            if let statIndex = rankedStats.firstIndex(where: { $0.id == stat.id }) {
                rankedStats[statIndex] = TeamStatistics(
                    id: stat.id,
                    teamNumber: stat.teamNumber,
                    eventName: stat.eventName,
                    seasonYear: stat.seasonYear,
                    opr: stat.opr,
                    dpr: stat.dpr,
                    ccwm: stat.ccwm,
                    matchesPlayed: stat.matchesPlayed,
                    wins: stat.wins,
                    losses: stat.losses,
                    ties: stat.ties,
                    averageScore: stat.averageScore,
                    averageAllianceScore: stat.averageAllianceScore,
                    averageOpponentScore: stat.averageOpponentScore,
                    highestScore: stat.highestScore,
                    lowestScore: stat.lowestScore,
                    averageAutoScore: stat.averageAutoScore,
                    averageTeleopScore: stat.averageTeleopScore,
                    averageEndgameScore: stat.averageEndgameScore,
                    winRate: stat.winRate,
                    consistencyScore: stat.consistencyScore,
                    oprRank: index + 1,
                    ccwmRank: sortedByCCWM.firstIndex(where: { $0.id == stat.id }).map { $0 + 1 },
                    winRateRank: sortedByWinRate.firstIndex(where: { $0.id == stat.id }).map { $0 + 1 },
                    lastCalculatedAt: stat.lastCalculatedAt,
                    calculationMethod: stat.calculationMethod,
                    matchesUsed: stat.matchesUsed
                )
            }
        }
        
        return rankedStats
    }
    
    /// Saves statistics to database
    func saveStatistics(_ statistics: [TeamStatistics]) async throws {
        for stat in statistics {
            struct StatisticsRecord: Encodable {
                let id: String
                let teamNumber: String
                let eventName: String?
                let seasonYear: Int?
                let opr: Double?
                let dpr: Double?
                let ccwm: Double?
                let matchesPlayed: Int
                let wins: Int
                let losses: Int
                let ties: Int
                let averageScore: Double?
                let averageAllianceScore: Double?
                let averageOpponentScore: Double?
                let highestScore: Int?
                let lowestScore: Int?
                let averageAutoScore: Double?
                let averageTeleopScore: Double?
                let averageEndgameScore: Double?
                let winRate: Double?
                let consistencyScore: Double?
                let oprRank: Int?
                let ccwmRank: Int?
                let winRateRank: Int?
                let lastCalculatedAt: String
                let calculationMethod: String
                let matchesUsed: Int?
            }
            
            let statRecord = StatisticsRecord(
                id: stat.id.uuidString,
                teamNumber: stat.teamNumber,
                eventName: stat.eventName,
                seasonYear: stat.seasonYear,
                opr: stat.opr,
                dpr: stat.dpr,
                ccwm: stat.ccwm,
                matchesPlayed: stat.matchesPlayed,
                wins: stat.wins,
                losses: stat.losses,
                ties: stat.ties,
                averageScore: stat.averageScore,
                averageAllianceScore: stat.averageAllianceScore,
                averageOpponentScore: stat.averageOpponentScore,
                highestScore: stat.highestScore,
                lowestScore: stat.lowestScore,
                averageAutoScore: stat.averageAutoScore,
                averageTeleopScore: stat.averageTeleopScore,
                averageEndgameScore: stat.averageEndgameScore,
                winRate: stat.winRate,
                consistencyScore: stat.consistencyScore,
                oprRank: stat.oprRank,
                ccwmRank: stat.ccwmRank,
                winRateRank: stat.winRateRank,
                lastCalculatedAt: ISO8601DateFormatter().string(from: stat.lastCalculatedAt),
                calculationMethod: stat.calculationMethod,
                matchesUsed: stat.matchesUsed
            )
            
            // Use upsert to handle conflicts
            try await supabase
                .from("team_statistics")
                .upsert(statRecord, onConflict: "team_number,event_name,season_year")
                .execute()
        }
    }
    
    /// Retrieves statistics for a specific team
    func getStatistics(teamNumber: String, eventName: String?) async throws -> TeamStatistics? {
        var query = supabase
            .from("team_statistics")
            .select()
            .eq("team_number", value: teamNumber)
        
        if let eventName = eventName {
            query = query.eq("event_name", value: eventName)
        }
        
        let stats: [TeamStatistics] = try await query
            .order("last_calculated_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        return stats.first
    }
    
    /// Retrieves rankings for an event
    func getRankings(eventName: String, metric: StatisticMetric, seasonYear: Int? = nil) async throws -> [TeamStatistics] {
        var query = supabase
            .from("team_statistics")
            .select()
            .eq("event_name", value: eventName)
        
        if let seasonYear = seasonYear {
            query = query.eq("season_year", value: seasonYear)
        }
        
        let orderColumn: String
        switch metric {
        case .opr:
            orderColumn = "opr"
        case .dpr:
            orderColumn = "dpr"
        case .ccwm:
            orderColumn = "ccwm"
        case .winRate:
            orderColumn = "win_rate"
        }
        
        let stats: [TeamStatistics] = try await query
            .order(orderColumn, ascending: false)
            .execute()
            .value
        
        return stats
    }
    
    /// Loads statistics from database
    func loadStatistics(eventName: String?, seasonYear: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var query = supabase
                .from("team_statistics")
                .select()
            
            if let eventName = eventName {
                query = query.eq("event_name", value: eventName)
            }
            
            if let seasonYear = seasonYear {
                query = query.eq("season_year", value: seasonYear)
            }
            
            let stats: [TeamStatistics] = try await query
                .order("opr", ascending: false)
                .execute()
                .value
            
            statistics = stats
        } catch {
            errorMessage = "Failed to load statistics: \(error.localizedDescription)"
        }
    }
}

// MARK: - Error Types

enum StatisticsError: LocalizedError {
    case insufficientData(String)
    case calculationFailed(String)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientData(let message):
            return "Insufficient data: \(message)"
        case .calculationFailed(let message):
            return "Calculation failed: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
