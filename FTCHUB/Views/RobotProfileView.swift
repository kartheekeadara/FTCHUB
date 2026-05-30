//
//  RobotProfileView.swift
//  FTCHUB
//
//  Phase 5: Robot Profile View
//  Display comprehensive robot profile
//

import SwiftUI

struct RobotProfileView: View {
    @StateObject private var pitService = PitScoutingService.shared
    let profile: PitScoutingService.RobotProfile
    @State private var showingEdit = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Team \(profile.teamNumber)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let eventName = profile.eventName {
                        Text(eventName)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.top)
                
                // Drivetrain Section
                ProfileSection(title: "Drivetrain") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        RobotInfoRow(label: "Type", value: profile.drivetrain.type.displayName)
                        RobotInfoRow(label: "Wheel Count", value: "\(profile.drivetrain.wheelCount)")
                        RobotInfoRow(label: "Wheel Type", value: profile.drivetrain.wheelType.displayName)
                        RobotInfoRow(label: "Motor Config", value: profile.drivetrain.motorConfig)
                        RatingRow(label: "Speed", rating: profile.drivetrain.speedRating)
                        RatingRow(label: "Maneuverability", rating: profile.drivetrain.maneuverabilityRating)
                    }
                }
                
                // Sensors Section
                ProfileSection(title: "Sensors & Electronics") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        ToggleRow(label: "IMU", value: profile.sensors.hasIMU)
                        ToggleRow(label: "Color Sensor", value: profile.sensors.hasColorSensor)
                        ToggleRow(label: "Distance Sensor", value: profile.sensors.hasDistanceSensor)
                        ToggleRow(label: "Camera", value: profile.sensors.hasCamera)
                        ToggleRow(label: "Limit Switches", value: profile.sensors.hasLimitSwitches)
                        ToggleRow(label: "Encoders", value: profile.sensors.hasEncoders)
                    }
                }
                
                // Autonomous Section
                ProfileSection(title: "Autonomous Capabilities") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        ToggleRow(label: "Can Score", value: profile.autonomous.canScore)
                        ToggleRow(label: "Can Navigate", value: profile.autonomous.canNavigate)
                        ToggleRow(label: "Can Collect", value: profile.autonomous.canCollect)
                        RatingRow(label: "Reliability", rating: profile.autonomous.reliability)
                        RobotInfoRow(label: "Average Score", value: String(format: "%.1f", profile.autonomous.averageScore))
                        if !profile.autonomous.notes.isEmpty {
                            Text(profile.autonomous.notes)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                // Teleop Section
                ProfileSection(title: "Tele-Op Features") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        RobotInfoRow(label: "Primary Function", value: profile.teleop.primaryFunction)
                        RatingRow(label: "Scoring Capability", rating: profile.teleop.scoringCapability)
                        RatingRow(label: "Speed", rating: profile.teleop.speedRating)
                        if !profile.teleop.notes.isEmpty {
                            Text(profile.teleop.notes)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                // Endgame Section
                ProfileSection(title: "Endgame Mechanisms") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        ToggleRow(label: "Can Hang", value: profile.endgame.canHang)
                        ToggleRow(label: "Can Park", value: profile.endgame.canPark)
                        ToggleRow(label: "Can Score", value: profile.endgame.canScore)
                        RobotInfoRow(label: "Success Rate", value: String(format: "%.0f%%", profile.endgame.successRate * 100))
                        if !profile.endgame.notes.isEmpty {
                            Text(profile.endgame.notes)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                // Dimensions Section
                ProfileSection(title: "Physical Specifications") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        RobotInfoRow(label: "Length", value: String(format: "%.1f\"", profile.dimensions.length))
                        RobotInfoRow(label: "Width", value: String(format: "%.1f\"", profile.dimensions.width))
                        RobotInfoRow(label: "Height", value: String(format: "%.1f\"", profile.dimensions.height))
                        if let weight = profile.dimensions.weight {
                            RobotInfoRow(label: "Weight", value: String(format: "%.1f lbs", weight))
                        }
                    }
                }
                
                // Power Section
                ProfileSection(title: "Power System") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        RobotInfoRow(label: "Battery Type", value: profile.powerSystem.batteryType)
                        RobotInfoRow(label: "Voltage", value: String(format: "%.1fV", profile.powerSystem.voltage))
                        if !profile.powerSystem.notes.isEmpty {
                            Text(profile.powerSystem.notes)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                // Strategic Section
                if !profile.strategicNotes.isEmpty || !profile.weaknesses.isEmpty || !profile.allianceSynergy.isEmpty {
                    ProfileSection(title: "Strategic Analysis") {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            if !profile.strategicNotes.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Notes")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(profile.strategicNotes)
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                            
                            if !profile.weaknesses.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Weaknesses")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(profile.weaknesses)
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                            
                            if !profile.allianceSynergy.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Alliance Synergy")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(profile.allianceSynergy)
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }
                    }
                }
                
                // Media Gallery
                if !profile.robotImages.isEmpty {
                    ProfileSection(title: "Robot Images") {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(profile.robotImages, id: \.self) { imageUrl in
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Robot Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            PitScoutingFormView()
        }
    }
}

// MARK: - Profile Section

fileprivate struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(title)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            content
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

// MARK: - Info Row

fileprivate struct RobotInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

// MARK: - Rating Row

fileprivate struct RatingRow: View {
    let label: String
    let rating: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? .yellow : .gray)
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Toggle Row

fileprivate struct ToggleRow: View {
    let label: String
    let value: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(value ? .green : .red)
        }
    }
}

#Preview {
    NavigationView {
        RobotProfileView(profile: PitScoutingService.RobotProfile(
            id: UUID(),
            teamNumber: "1234",
            eventName: "Regional",
            drivetrain: PitScoutingService.DrivetrainConfig(
                type: .mecanum,
                wheelCount: 4,
                wheelType: .mecanum,
                motorConfig: "4x NeveRest",
                speedRating: 4,
                maneuverabilityRating: 5
            ),
            sensors: PitScoutingService.SensorConfig(
                hasIMU: true,
                hasColorSensor: true,
                hasDistanceSensor: false,
                hasCamera: false,
                hasLimitSwitches: true,
                hasEncoders: true,
                customSensors: []
            ),
            autonomous: PitScoutingService.AutonomousCapabilities(
                canScore: true,
                canNavigate: true,
                canCollect: false,
                reliability: 4,
                averageScore: 15.0,
                notes: "Consistent autonomous"
            ),
            teleop: PitScoutingService.TeleopFeatures(
                primaryFunction: "Scoring",
                mechanisms: ["Intake", "Shooter"],
                scoringCapability: 5,
                speedRating: 4,
                notes: "High scoring robot"
            ),
            endgame: PitScoutingService.EndgameMechanisms(
                canHang: true,
                canPark: true,
                canScore: false,
                successRate: 0.85,
                notes: "Reliable hanging"
            ),
            dimensions: PitScoutingService.RobotDimensions(
                length: 18.0,
                width: 18.0,
                height: 18.0,
                weight: 35.0
            ),
            powerSystem: PitScoutingService.PowerSystem(
                batteryType: "12V",
                voltage: 12.0,
                notes: "Standard battery"
            ),
            strategicNotes: "Strong offensive robot",
            weaknesses: "Weak defense",
            allianceSynergy: "Works well with defensive partners",
            robotImages: [],
            robotVideos: [],
            profileVersion: 1,
            isCurrent: true,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
