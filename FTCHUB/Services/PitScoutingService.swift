//
//  PitScoutingService.swift
//  FTCHUB
//
//  Phase 5: Virtual Pit Scouting
//  Comprehensive robot profile management
//

import Foundation
import Combine
import Supabase
import UIKit

@MainActor
class PitScoutingService: ObservableObject {
    static let shared = PitScoutingService()
    
    @Published var profiles: [RobotProfile] = []
    @Published var currentProfile: RobotProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Data Models
    
    struct RobotProfile: Codable, Identifiable {
        let id: UUID
        let teamNumber: String
        let eventName: String?
        let drivetrain: DrivetrainConfig
        let sensors: SensorConfig
        let autonomous: AutonomousCapabilities
        let teleop: TeleopFeatures
        let endgame: EndgameMechanisms
        let dimensions: RobotDimensions
        let powerSystem: PowerSystem
        let strategicNotes: String
        let weaknesses: String
        let allianceSynergy: String
        let robotImages: [String]
        let robotVideos: [String]
        let profileVersion: Int
        let isCurrent: Bool
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamNumber = "scouted_team_number"
            case eventName = "event_name"
            case drivetrain
            case sensors
            case autonomous
            case teleop
            case endgame
            case dimensions
            case powerSystem = "power_system"
            case strategicNotes = "strategic_notes"
            case weaknesses
            case allianceSynergy = "alliance_synergy"
            case robotImages = "robot_images"
            case robotVideos = "robot_videos"
            case profileVersion = "profile_version"
            case isCurrent = "is_current_profile"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    struct DrivetrainConfig: Codable {
        let type: DrivetrainType
        let wheelCount: Int
        let wheelType: WheelType
        let motorConfig: String
        let speedRating: Int // 1-5
        let maneuverabilityRating: Int // 1-5
        
        enum CodingKeys: String, CodingKey {
            case type
            case wheelCount = "wheel_count"
            case wheelType = "wheel_type"
            case motorConfig = "motor_config"
            case speedRating = "speed_rating"
            case maneuverabilityRating = "maneuverability_rating"
        }
    }
    
    enum DrivetrainType: String, Codable, CaseIterable {
        case tank = "tank"
        case mecanum = "mecanum"
        case swerve = "swerve"
        case omni = "omni"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .tank: return "Tank Drive"
            case .mecanum: return "Mecanum"
            case .swerve: return "Swerve"
            case .omni: return "Omni Wheel"
            case .other: return "Other"
            }
        }
    }
    
    enum WheelType: String, Codable, CaseIterable {
        case traction = "traction"
        case omni = "omni"
        case mecanum = "mecanum"
        case other = "other"
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    struct SensorConfig: Codable {
        let hasIMU: Bool
        let hasColorSensor: Bool
        let hasDistanceSensor: Bool
        let hasCamera: Bool
        let hasLimitSwitches: Bool
        let hasEncoders: Bool
        let customSensors: [String]
        
        enum CodingKeys: String, CodingKey {
            case hasIMU = "has_imu"
            case hasColorSensor = "has_color_sensor"
            case hasDistanceSensor = "has_distance_sensor"
            case hasCamera = "has_camera"
            case hasLimitSwitches = "has_limit_switches"
            case hasEncoders = "has_encoders"
            case customSensors = "custom_sensors"
        }
    }
    
    struct AutonomousCapabilities: Codable {
        let canScore: Bool
        let canNavigate: Bool
        let canCollect: Bool
        let reliability: Int // 1-5
        let averageScore: Double
        let notes: String
        
        enum CodingKeys: String, CodingKey {
            case canScore = "can_score"
            case canNavigate = "can_navigate"
            case canCollect = "can_collect"
            case reliability
            case averageScore = "average_score"
            case notes
        }
    }
    
    struct TeleopFeatures: Codable {
        let primaryFunction: String
        let mechanisms: [String]
        let scoringCapability: Int // 1-5
        let speedRating: Int // 1-5
        let notes: String
        
        enum CodingKeys: String, CodingKey {
            case primaryFunction = "primary_function"
            case mechanisms
            case scoringCapability = "scoring_capability"
            case speedRating = "speed_rating"
            case notes
        }
    }
    
    struct EndgameMechanisms: Codable {
        let canHang: Bool
        let canPark: Bool
        let canScore: Bool
        let successRate: Double // 0-1
        let notes: String
        
        enum CodingKeys: String, CodingKey {
            case canHang = "can_hang"
            case canPark = "can_park"
            case canScore = "can_score"
            case successRate = "success_rate"
            case notes
        }
    }
    
    struct RobotDimensions: Codable {
        let length: Double // inches
        let width: Double // inches
        let height: Double // inches
        let weight: Double? // pounds
        
        enum CodingKeys: String, CodingKey {
            case length
            case width
            case height
            case weight
        }
    }
    
    struct PowerSystem: Codable {
        let batteryType: String
        let voltage: Double
        let notes: String
        
        enum CodingKeys: String, CodingKey {
            case batteryType = "battery_type"
            case voltage
            case notes
        }
    }
    
    struct TeamComparison: Codable, Identifiable {
        let id: UUID
        let teamNumber: String
        let profile: RobotProfile
        let differences: [String]
        let strengths: [String]
        let weaknesses: [String]
    }
    
    // MARK: - Profile Creation
    
    func createPitScoutingProfile(
        teamNumber: String,
        eventName: String,
        profile: RobotProfile,
        images: [UIImage]?,
        teamId: UUID
    ) async throws -> ScoutingReport {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // 1. Mark old profiles as not current
            try await markOldProfilesAsInactive(teamNumber: teamNumber, eventName: eventName, teamId: teamId)
            
            // 2. Upload images if provided
            var imageUrls: [String] = []
            if let images = images {
                for image in images {
                    let url = try await uploadRobotImage(image, reportId: UUID())
                    imageUrls.append(url)
                }
            }
            
            // 3. Create profile data dictionary
            let profileData = try createProfileDataDict(profile: profile, imageUrls: imageUrls)
            
            // 4. Create new scouting report
            let report = ScoutingReport(
                id: UUID(),
                teamId: teamId,
                templateId: nil,
                scoutedTeamNumber: teamNumber,
                matchNumber: nil,
                eventName: eventName,
                phase: nil,
                scoutId: nil,
                reportData: [:],
                notes: profile.strategicNotes,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // 5. Save to database
            // Encode profileData to JSON string for JSONB column
            let profileDataJSON = try JSONSerialization.data(withJSONObject: profileData)
            let profileDataString = String(data: profileDataJSON, encoding: .utf8) ?? "{}"
            
            struct ReportRecord: Encodable {
                let id: String
                let teamId: String
                let scoutedTeamNumber: String
                let eventName: String
                let isPitScouting: Bool
                let pitScoutingData: String
                let robotImages: [String]
                let robotVideos: [String]
                let profileVersion: Int
                let isCurrentProfile: Bool
                let notes: String?
                let createdAt: String
                let updatedAt: String
            }
            
            let reportRecord = ReportRecord(
                id: report.id.uuidString,
                teamId: teamId.uuidString,
                scoutedTeamNumber: teamNumber,
                eventName: eventName,
                isPitScouting: true,
                pitScoutingData: profileDataString,
                robotImages: imageUrls,
                robotVideos: [],
                profileVersion: profile.profileVersion,
                isCurrentProfile: true,
                notes: profile.strategicNotes,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("scouting_reports")
                .insert(reportRecord)
                .execute()
            
            return report
            
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Profile Retrieval
    
    func getCurrentProfile(teamNumber: String, eventName: String?) async throws -> RobotProfile? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var query = supabase
                .from("scouting_reports")
                .select()
                .eq("scouted_team_number", value: teamNumber)
                .eq("is_pit_scouting", value: true)
                .eq("is_current_profile", value: true)
            
            if let eventName = eventName {
                query = query.eq("event_name", value: eventName)
            }
            
            let reports: [ScoutingReport] = try await query
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            guard let report = reports.first else {
                return nil
            }
            
            return try parseProfileFromReport(report)
            
        } catch {
            errorMessage = "Failed to retrieve profile: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Profile Comparison
    
    func compareProfiles(teamNumbers: [String], eventName: String?) async throws -> [TeamComparison] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var comparisons: [TeamComparison] = []
            
            for teamNumber in teamNumbers {
                if let profile = try await getCurrentProfile(teamNumber: teamNumber, eventName: eventName) {
                    let (differences, strengths, weaknesses) = analyzeProfile(profile)
                    
                    comparisons.append(TeamComparison(
                        id: UUID(),
                        teamNumber: teamNumber,
                        profile: profile,
                        differences: differences,
                        strengths: strengths,
                        weaknesses: weaknesses
                    ))
                }
            }
            
            return comparisons
            
        } catch {
            errorMessage = "Failed to compare profiles: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Media Management
    
    func uploadRobotImage(_ image: UIImage, reportId: UUID) async throws -> String {
        // Compress image (max 3MB)
        guard let imageData = compressImage(image, maxSizeMB: 3) else {
            throw PitScoutingError.imageProcessingFailed("Failed to compress image")
        }
        
        // Upload to Supabase Storage
        let fileName = "\(reportId.uuidString)-\(UUID().uuidString).jpg"
        
        do {
            try await supabase.storage
                .from("robot_images")
                .upload(fileName, data: imageData)
            
            // Get public URL
            let url = try supabase.storage
                .from("robot_images")
                .getPublicURL(path: fileName)
            
            return url.absoluteString
            
        } catch {
            throw PitScoutingError.uploadFailed("Failed to upload image: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func markOldProfilesAsInactive(teamNumber: String, eventName: String, teamId: UUID) async throws {
        try await supabase
            .from("scouting_reports")
            .update(["is_current_profile": false])
            .eq("scouted_team_number", value: teamNumber)
            .eq("event_name", value: eventName)
            .eq("is_pit_scouting", value: true)
            .eq("team_id", value: teamId)
            .execute()
    }
    
    private func createProfileDataDict(profile: RobotProfile, imageUrls: [String]) throws -> [String: Any] {
        let encoder = JSONEncoder()
        
        return [
            "drivetrain": try encoder.encode(profile.drivetrain),
            "sensors": try encoder.encode(profile.sensors),
            "autonomous": try encoder.encode(profile.autonomous),
            "teleop": try encoder.encode(profile.teleop),
            "endgame": try encoder.encode(profile.endgame),
            "dimensions": try encoder.encode(profile.dimensions),
            "power_system": try encoder.encode(profile.powerSystem),
            "strategic_notes": profile.strategicNotes,
            "weaknesses": profile.weaknesses,
            "alliance_synergy": profile.allianceSynergy,
            "robot_images": imageUrls,
            "robot_videos": profile.robotVideos
        ]
    }
    
    private func parseProfileFromReport(_ report: ScoutingReport) throws -> RobotProfile {
        // Parse pit_scouting_data JSONB
        // This is simplified - would need actual JSON parsing
        // For now, create a default profile structure
        
        let defaultDrivetrain = DrivetrainConfig(
            type: .tank,
            wheelCount: 4,
            wheelType: .traction,
            motorConfig: "Unknown",
            speedRating: 3,
            maneuverabilityRating: 3
        )
        
        let defaultSensors = SensorConfig(
            hasIMU: false,
            hasColorSensor: false,
            hasDistanceSensor: false,
            hasCamera: false,
            hasLimitSwitches: false,
            hasEncoders: false,
            customSensors: []
        )
        
        let defaultAutonomous = AutonomousCapabilities(
            canScore: false,
            canNavigate: false,
            canCollect: false,
            reliability: 3,
            averageScore: 0.0,
            notes: ""
        )
        
        let defaultTeleop = TeleopFeatures(
            primaryFunction: "Unknown",
            mechanisms: [],
            scoringCapability: 3,
            speedRating: 3,
            notes: ""
        )
        
        let defaultEndgame = EndgameMechanisms(
            canHang: false,
            canPark: false,
            canScore: false,
            successRate: 0.0,
            notes: ""
        )
        
        let defaultDimensions = RobotDimensions(
            length: 18.0,
            width: 18.0,
            height: 18.0,
            weight: nil
        )
        
        let defaultPower = PowerSystem(
            batteryType: "Unknown",
            voltage: 12.0,
            notes: ""
        )
        
        return RobotProfile(
            id: report.id,
            teamNumber: report.scoutedTeamNumber,
            eventName: report.eventName,
            drivetrain: defaultDrivetrain,
            sensors: defaultSensors,
            autonomous: defaultAutonomous,
            teleop: defaultTeleop,
            endgame: defaultEndgame,
            dimensions: defaultDimensions,
            powerSystem: defaultPower,
            strategicNotes: report.notes ?? "",
            weaknesses: "",
            allianceSynergy: "",
            robotImages: [],
            robotVideos: [],
            profileVersion: 1,
            isCurrent: true,
            createdAt: report.createdAt,
            updatedAt: report.updatedAt
        )
    }
    
    private func analyzeProfile(_ profile: RobotProfile) -> (differences: [String], strengths: [String], weaknesses: [String]) {
        let differences: [String] = []
        var strengths: [String] = []
        var weaknesses: [String] = []
        
        // Analyze drivetrain
        if profile.drivetrain.speedRating >= 4 {
            strengths.append("Fast drivetrain")
        } else if profile.drivetrain.speedRating <= 2 {
            weaknesses.append("Slow drivetrain")
        }
        
        // Analyze autonomous
        if profile.autonomous.reliability >= 4 {
            strengths.append("Reliable autonomous")
        } else if profile.autonomous.reliability <= 2 {
            weaknesses.append("Unreliable autonomous")
        }
        
        // Analyze endgame
        if profile.endgame.canHang {
            strengths.append("Can hang")
        }
        if profile.endgame.successRate < 0.5 {
            weaknesses.append("Low endgame success rate")
        }
        
        return (differences, strengths, weaknesses)
    }
    
    private func compressImage(_ image: UIImage, maxSizeMB: Int) -> Data? {
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        let maxSizeBytes = maxSizeMB * 1024 * 1024
        
        while let data = imageData, data.count > maxSizeBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
}

// MARK: - Error Types

enum PitScoutingError: LocalizedError {
    case profileNotFound(String)
    case creationFailed(String)
    case updateFailed(String)
    case imageProcessingFailed(String)
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .profileNotFound(let message):
            return "Profile not found: \(message)"
        case .creationFailed(let message):
            return "Failed to create profile: \(message)"
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        case .imageProcessingFailed(let message):
            return "Image processing failed: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}
