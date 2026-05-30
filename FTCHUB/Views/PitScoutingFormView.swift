//
//  PitScoutingFormView.swift
//  FTCHUB
//
//  Phase 5: Pit Scouting Form
//  Create and edit robot profiles
//

import SwiftUI

struct PitScoutingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var pitService = PitScoutingService.shared
    @EnvironmentObject var teamService: TeamService
    
    @State private var teamNumber = ""
    @State private var eventName = ""
    
    // Drivetrain
    @State private var drivetrainType: PitScoutingService.DrivetrainType = .tank
    @State private var wheelCount = 4
    @State private var wheelType: PitScoutingService.WheelType = .traction
    @State private var motorConfig = ""
    @State private var speedRating = 3
    @State private var maneuverabilityRating = 3
    
    // Sensors
    @State private var hasIMU = false
    @State private var hasColorSensor = false
    @State private var hasDistanceSensor = false
    @State private var hasCamera = false
    @State private var hasLimitSwitches = false
    @State private var hasEncoders = false
    @State private var customSensors: [String] = []
    
    // Autonomous
    @State private var canScore = false
    @State private var canNavigate = false
    @State private var canCollect = false
    @State private var autonomousReliability = 3
    @State private var averageAutoScore = 0.0
    @State private var autonomousNotes = ""
    
    // Teleop
    @State private var primaryFunction = ""
    @State private var mechanisms: [String] = []
    @State private var scoringCapability = 3
    @State private var teleopSpeedRating = 3
    @State private var teleopNotes = ""
    
    // Endgame
    @State private var canHang = false
    @State private var canPark = false
    @State private var canScoreEndgame = false
    @State private var endgameSuccessRate = 0.0
    @State private var endgameNotes = ""
    
    // Dimensions
    @State private var length = 18.0
    @State private var width = 18.0
    @State private var height = 18.0
    @State private var weight: Double?
    
    // Power
    @State private var batteryType = ""
    @State private var voltage = 12.0
    @State private var powerNotes = ""
    
    // Strategic
    @State private var strategicNotes = ""
    @State private var weaknesses = ""
    @State private var allianceSynergy = ""
    
    // Media
    @State private var selectedImages: [UIImage] = []
    
    @State private var isSaving = false
    
    var body: some View {
        Form {
                // Basic Information
                Section("Basic Information") {
                    TextField("Team Number", text: $teamNumber)
                        .keyboardType(.numberPad)
                    TextField("Event Name", text: $eventName)
                }
                
                // Drivetrain
                Section("Drivetrain Configuration") {
                    Picker("Type", selection: $drivetrainType) {
                        ForEach(PitScoutingService.DrivetrainType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Stepper("Wheel Count: \(wheelCount)", value: $wheelCount, in: 2...8)
                    
                    Picker("Wheel Type", selection: $wheelType) {
                        ForEach(PitScoutingService.WheelType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Motor Configuration", text: $motorConfig)
                    
                    Stepper("Speed Rating: \(speedRating)/5", value: $speedRating, in: 1...5)
                    Stepper("Maneuverability: \(maneuverabilityRating)/5", value: $maneuverabilityRating, in: 1...5)
                }
                
                // Sensors
                Section("Sensors & Electronics") {
                    Toggle("IMU", isOn: $hasIMU)
                    Toggle("Color Sensor", isOn: $hasColorSensor)
                    Toggle("Distance Sensor", isOn: $hasDistanceSensor)
                    Toggle("Camera", isOn: $hasCamera)
                    Toggle("Limit Switches", isOn: $hasLimitSwitches)
                    Toggle("Encoders", isOn: $hasEncoders)
                }
                
                // Autonomous
                Section("Autonomous Capabilities") {
                    Toggle("Can Score", isOn: $canScore)
                    Toggle("Can Navigate", isOn: $canNavigate)
                    Toggle("Can Collect", isOn: $canCollect)
                    Stepper("Reliability: \(autonomousReliability)/5", value: $autonomousReliability, in: 1...5)
                    TextField("Average Auto Score", value: $averageAutoScore, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Notes", text: $autonomousNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Teleop
                Section("Tele-Op Features") {
                    TextField("Primary Function", text: $primaryFunction)
                    Stepper("Scoring Capability: \(scoringCapability)/5", value: $scoringCapability, in: 1...5)
                    Stepper("Speed Rating: \(teleopSpeedRating)/5", value: $teleopSpeedRating, in: 1...5)
                    TextField("Notes", text: $teleopNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Endgame
                Section("Endgame Mechanisms") {
                    Toggle("Can Hang", isOn: $canHang)
                    Toggle("Can Park", isOn: $canPark)
                    Toggle("Can Score", isOn: $canScoreEndgame)
                    TextField("Success Rate", value: $endgameSuccessRate, format: .percent)
                        .keyboardType(.decimalPad)
                    TextField("Notes", text: $endgameNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Dimensions
                Section("Physical Specifications") {
                    TextField("Length (inches)", value: $length, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Width (inches)", value: $width, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Height (inches)", value: $height, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Weight (lbs)", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                // Power
                Section("Power System") {
                    TextField("Battery Type", text: $batteryType)
                    TextField("Voltage", value: $voltage, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Notes", text: $powerNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Strategic
                Section("Strategic Analysis") {
                    TextField("Strategic Notes", text: $strategicNotes, axis: .vertical)
                        .lineLimit(5...10)
                    TextField("Weaknesses", text: $weaknesses, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Alliance Synergy", text: $allianceSynergy, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Media
                Section("Media") {
                    Button {
                        // Open image picker
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                            Text("Add Photos")
                        }
                    }
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
        }
        .navigationTitle("Pit Scouting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(teamNumber.isEmpty || isSaving)
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        // Create profile data
        let drivetrain = PitScoutingService.DrivetrainConfig(
            type: drivetrainType,
            wheelCount: wheelCount,
            wheelType: wheelType,
            motorConfig: motorConfig,
            speedRating: speedRating,
            maneuverabilityRating: maneuverabilityRating
        )
        
        let sensors = PitScoutingService.SensorConfig(
            hasIMU: hasIMU,
            hasColorSensor: hasColorSensor,
            hasDistanceSensor: hasDistanceSensor,
            hasCamera: hasCamera,
            hasLimitSwitches: hasLimitSwitches,
            hasEncoders: hasEncoders,
            customSensors: customSensors
        )
        
        let autonomous = PitScoutingService.AutonomousCapabilities(
            canScore: canScore,
            canNavigate: canNavigate,
            canCollect: canCollect,
            reliability: autonomousReliability,
            averageScore: averageAutoScore,
            notes: autonomousNotes
        )
        
        let teleop = PitScoutingService.TeleopFeatures(
            primaryFunction: primaryFunction,
            mechanisms: mechanisms,
            scoringCapability: scoringCapability,
            speedRating: teleopSpeedRating,
            notes: teleopNotes
        )
        
        let endgame = PitScoutingService.EndgameMechanisms(
            canHang: canHang,
            canPark: canPark,
            canScore: canScoreEndgame,
            successRate: endgameSuccessRate,
            notes: endgameNotes
        )
        
        let dimensions = PitScoutingService.RobotDimensions(
            length: length,
            width: width,
            height: height,
            weight: weight
        )
        
        let power = PitScoutingService.PowerSystem(
            batteryType: batteryType,
            voltage: voltage,
            notes: powerNotes
        )
        
        let profile = PitScoutingService.RobotProfile(
            id: UUID(),
            teamNumber: teamNumber,
            eventName: eventName.isEmpty ? nil : eventName,
            drivetrain: drivetrain,
            sensors: sensors,
            autonomous: autonomous,
            teleop: teleop,
            endgame: endgame,
            dimensions: dimensions,
            powerSystem: power,
            strategicNotes: strategicNotes,
            weaknesses: weaknesses,
            allianceSynergy: allianceSynergy,
            robotImages: [],
            robotVideos: [],
            profileVersion: 1,
            isCurrent: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            if let teamId = teamService.currentTeam?.id {
                do {
                    _ = try await pitService.createPitScoutingProfile(
                        teamNumber: teamNumber,
                        eventName: eventName,
                        profile: profile,
                        images: selectedImages.isEmpty ? nil : selectedImages,
                        teamId: teamId
                    )
                    dismiss()
                } catch {
                    // Handle error
                }
            }
            isSaving = false
        }
    }
}

#Preview {
    PitScoutingFormView()
}
