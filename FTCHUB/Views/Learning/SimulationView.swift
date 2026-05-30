//
//  SimulationView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

// MARK: - Simulation Types
enum SimulationType {
    case drivetrainConfigurator
    case scoringCalculator
    case mechanismDesigner
}

struct SimulationView: View {
    let type: SimulationType
    let moduleColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    switch type {
                    case .drivetrainConfigurator:
                        DrivetrainConfiguratorView(moduleColor: moduleColor)
                    case .scoringCalculator:
                        LearningScoringCalculatorView(moduleColor: moduleColor)
                    case .mechanismDesigner:
                        MechanismDesignerView(moduleColor: moduleColor)
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(simulationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var simulationTitle: String {
        switch type {
        case .drivetrainConfigurator: return "Drivetrain Configurator"
        case .scoringCalculator: return "Scoring Calculator"
        case .mechanismDesigner: return "Mechanism Designer"
        }
    }
}

// MARK: - Drivetrain Configurator
struct DrivetrainConfiguratorView: View {
    let moduleColor: Color
    @State private var selectedMotor = "REV HD Hex Motor"
    @State private var gearRatio = "20:1"
    @State private var wheelDiameter = "4.0"
    @State private var motorCount = 4
    
    private let motors = ["REV HD Hex Motor", "REV Core Hex Motor", "goBILDA 5202", "goBILDA 5203"]
    private let gearRatios = ["20:1", "40:1", "60:1", "84:1", "120:1"]
    private let wheelDiameters = ["3.0", "3.5", "4.0", "4.5", "5.0"]
    
    private var calculatedSpeed: Double {
        // Simplified calculation - in reality would use motor specs
        let baseSpeed = 6000.0 // RPM
        let ratio = Double(gearRatio.components(separatedBy: ":")[0]) ?? 1.0
        let speed = baseSpeed / ratio
        return speed * Double.pi * (Double(wheelDiameter) ?? 4.0) / 12.0 / 60.0 // Convert to ft/s
    }
    
    private var calculatedTorque: Double {
        // Simplified calculation
        let baseTorque = 5.2 // Nm
        let ratio = Double(gearRatio.components(separatedBy: ":")[0]) ?? 1.0
        return baseTorque * ratio
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Configure your drivetrain and see how it affects performance")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Configuration
            VStack(alignment: .leading, spacing: 16) {
                // Motor selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Motor")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Picker("Motor", selection: $selectedMotor) {
                        ForEach(motors, id: \.self) { motor in
                            Text(motor).tag(motor)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                
                // Gear ratio
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gear Ratio")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Picker("Gear Ratio", selection: $gearRatio) {
                        ForEach(gearRatios, id: \.self) { ratio in
                            Text(ratio).tag(ratio)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Wheel diameter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wheel Diameter (inches)")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Picker("Wheel Diameter", selection: $wheelDiameter) {
                        ForEach(wheelDiameters, id: \.self) { diameter in
                            Text("\(diameter)\"").tag(diameter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Motor count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of Motors")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Stepper("\(motorCount) motors", value: $motorCount, in: 2...8)
                        .padding()
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
            
            // Results
            VStack(alignment: .leading, spacing: 16) {
                Text("Performance Metrics")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack(spacing: 20) {
                    SimulationMetricCard(
                        title: "Speed",
                        value: String(format: "%.1f", calculatedSpeed),
                        unit: "ft/s",
                        color: .blue
                    )
                    
                    SimulationMetricCard(
                        title: "Torque",
                        value: String(format: "%.1f", calculatedTorque),
                        unit: "Nm",
                        color: .orange
                    )
                }
                
                // Tradeoff visualization
                TradeoffVisualizationView(
                    speed: calculatedSpeed,
                    torque: calculatedTorque,
                    moduleColor: moduleColor
                )
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.lg)
        }
    }
}

private struct SimulationMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(unit)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct TradeoffVisualizationView: View {
    let speed: Double
    let torque: Double
    let moduleColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Speed vs Torque Tradeoff")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Simplified visualization
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speed")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(DesignSystem.Colors.secondaryBackground)
                                .frame(height: 20)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * min(speed / 10.0, 1.0), height: 20)
                        }
                    }
                    .frame(height: 20)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Torque")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(DesignSystem.Colors.secondaryBackground)
                                .frame(height: 20)
                            
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * min(torque / 50.0, 1.0), height: 20)
                        }
                    }
                    .frame(height: 20)
                }
            }
            
            Text("Higher gear ratios increase torque but decrease speed")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .italic()
        }
    }
}

// MARK: - Scoring Calculator
private struct LearningScoringCalculatorView: View {
    let moduleColor: Color
    @State private var gameElements: [GameElement] = []
    @State private var totalScore = 0
    
    struct GameElement: Identifiable {
        let id = UUID()
        var name: String
        var points: Int
        var count: Int
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Calculate potential match scores")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Score elements
            VStack(alignment: .leading, spacing: 16) {
                ForEach(gameElements) { element in
                    HStack {
                        TextField("Element name", text: Binding(
                            get: { element.name },
                            set: { _ in }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        Stepper("\(element.count)", value: Binding(
                            get: { element.count },
                            set: { _ in }
                        ), in: 0...20)
                        
                        Text("\(element.points) pts")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .frame(width: 60)
                    }
                }
                
                Button(action: {
                    gameElements.append(GameElement(name: "New Element", points: 0, count: 0))
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Element")
                    }
                    .font(.subheadline)
                    .foregroundColor(moduleColor)
                }
            }
            
            // Total score
            VStack(spacing: 8) {
                Text("Total Score")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Text("\(totalScore)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(moduleColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(moduleColor.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.lg)
        }
    }
}

// MARK: - Mechanism Designer
struct MechanismDesignerView: View {
    let moduleColor: Color
    @State private var selectedComponents: [String] = []
    
    private let availableComponents = [
        "Motor", "Servo", "Linear Slide", "Arm", "Intake", "Outtake", "Claw"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Design your mechanism by selecting components")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Component selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Components")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(availableComponents, id: \.self) { component in
                        ComponentCard(
                            name: component,
                            isSelected: selectedComponents.contains(component),
                            moduleColor: moduleColor
                        ) {
                            if selectedComponents.contains(component) {
                                selectedComponents.removeAll { $0 == component }
                            } else {
                                selectedComponents.append(component)
                            }
                        }
                    }
                }
            }
            
            // Selected components
            if !selectedComponents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Design")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(selectedComponents, id: \.self) { component in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(component)
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .padding()
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                }
            }
        }
    }
}

struct ComponentCard: View {
    let name: String
    let isSelected: Bool
    let moduleColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: componentIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? moduleColor : DesignSystem.Colors.textSecondary)
                Text(name)
                    .font(.caption)
                    .foregroundColor(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? moduleColor.opacity(0.1) : DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        isSelected ? moduleColor : DesignSystem.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var componentIcon: String {
        switch name {
        case "Motor": return "bolt.fill"
        case "Servo": return "gearshape.fill"
        case "Linear Slide": return "arrow.up.and.down"
        case "Arm": return "hand.raised.fill"
        case "Intake": return "arrow.down.circle.fill"
        case "Outtake": return "arrow.up.circle.fill"
        case "Claw": return "hand.point.up.left.fill"
        default: return "cube.fill"
        }
    }
}

