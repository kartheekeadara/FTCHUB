//
//  ScoutingTemplate.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct ScoutingTemplate: Identifiable, Codable {
    let id: UUID
    var teamId: UUID
    var name: String
    var description: String?
    var isDefault: Bool
    var templateData: ScoutingFormData
    var createdBy: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case name
        case description
        case isDefault = "is_default"
        case templateData = "template_data"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ScoutingFormData: Codable {
    var sections: [ScoutingSection]
    var version: String
    var lastModified: Date
    
    init() {
        self.sections = []
        self.version = "1.0"
        self.lastModified = Date()
    }
}

struct ScoutingSection: Codable, Identifiable {
    let id: UUID
    var title: String
    var fields: [ScoutingField]
    var order: Int
    
    init(title: String, fields: [ScoutingField] = [], order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.fields = fields
        self.order = order
    }
}

struct ScoutingField: Codable, Identifiable {
    let id: UUID
    var type: ScoutingFieldType
    var title: String
    var description: String?
    var isRequired: Bool
    var options: [String]? // For multiple choice fields
    var minValue: Double?
    var maxValue: Double?
    var step: Double?
    var order: Int
    
    init(type: ScoutingFieldType, title: String, description: String? = nil, isRequired: Bool = false, options: [String]? = nil, minValue: Double? = nil, maxValue: Double? = nil, step: Double? = nil, order: Int = 0) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.isRequired = isRequired
        self.options = options
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.order = order
    }
}

enum ScoutingFieldType: String, Codable, CaseIterable {
    case text = "text"
    case number = "number"
    case slider = "slider"
    case multipleChoice = "multiple_choice"
    case boolean = "boolean"
    case rating = "rating"
    case notes = "notes"
    
    var displayName: String {
        switch self {
        case .text: return "Text Input"
        case .number: return "Number Input"
        case .slider: return "Slider"
        case .multipleChoice: return "Multiple Choice"
        case .boolean: return "Yes/No"
        case .rating: return "Rating (1-5)"
        case .notes: return "Notes"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "textformat"
        case .number: return "number"
        case .slider: return "slider.horizontal.3"
        case .multipleChoice: return "list.bullet"
        case .boolean: return "checkmark.circle"
        case .rating: return "star"
        case .notes: return "note.text"
        }
    }
}

// MARK: - Sample Data
extension ScoutingTemplate {
    static var sample: ScoutingTemplate {
        let teamId = UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") ?? UUID()
        return ScoutingTemplate.defaultDecode(teamId: teamId)
    }
    
    static func defaultDecode(teamId: UUID, createdAt: Date = Date()) -> ScoutingTemplate {
        var formData = ScoutingFormData()
        formData.sections = decodeSections()
        formData.lastModified = createdAt
        
        return ScoutingTemplate(
            id: UUID(),
            teamId: teamId,
            name: "DECODE Match Scouting",
            description: "Standard FTC DECODE match template covering autonomous, teleop, and endgame performance.",
            isDefault: true,
            templateData: formData,
            createdBy: nil,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
    
    private static func decodeSections() -> [ScoutingSection] {
        [
            ScoutingSection(title: "Pre-Match", fields: [
                ScoutingField(type: .boolean, title: "Robot Visible Before Match", description: "Robot present at inspection?", isRequired: true, order: 0),
                ScoutingField(type: .multipleChoice, title: "Alliance Color", isRequired: true, options: ["Red", "Blue"], order: 1),
                ScoutingField(type: .multipleChoice, title: "Starting Position", isRequired: true, options: ["Gate 1", "Gate 2", "Fence 1", "Fence 2"], order: 2),
                ScoutingField(type: .notes, title: "Pre-Match Notes", description: "Observations before match starts", order: 3)
            ], order: 0),
            ScoutingSection(title: "Autonomous (30 seconds)", fields: [
                ScoutingField(type: .boolean, title: "Green Artifacts Scored", description: "Green artifacts in correct scoring locations?", order: 0),
                ScoutingField(type: .number, title: "Green Artifacts in Correct Zones", description: "Count of green artifacts correctly placed", minValue: 0, maxValue: 10, order: 1),
                ScoutingField(type: .boolean, title: "Purple Artifacts Scored", description: "Purple artifacts in correct scoring locations?", order: 2),
                ScoutingField(type: .number, title: "Purple Artifacts in Correct Zones", description: "Count of purple artifacts correctly placed", minValue: 0, maxValue: 10, order: 3),
                ScoutingField(type: .boolean, title: "Robot Leaves Starting Zone", description: "Robot successfully crossed start line?", order: 4),
                ScoutingField(type: .rating, title: "Autonomous Reliability", description: "Consistency of autonomous routine", maxValue: 5, order: 5),
                ScoutingField(type: .notes, title: "Autonomous Notes", description: "Pattern route, classifier usage, notable events", order: 6)
            ], order: 1),
            ScoutingSection(title: "Teleop (120 seconds)", fields: [
                ScoutingField(type: .number, title: "Green Artifacts Placed", description: "Total green artifacts in teleop", minValue: 0, maxValue: 50, order: 0),
                ScoutingField(type: .number, title: "Purple Artifacts Placed", description: "Total purple artifacts in teleop", minValue: 0, maxValue: 50, order: 1),
                ScoutingField(type: .number, title: "Overflow / Gate Classifier Cycles", description: "Classifier cycles completed", minValue: 0, maxValue: 50, order: 2),
                ScoutingField(type: .boolean, title: "Alliance Coordination", description: "Coordinated strategy with partner?", order: 3),
                ScoutingField(type: .slider, title: "Driving Quality", description: "Driver control quality", minValue: 1, maxValue: 5, step: 1, order: 4),
                ScoutingField(type: .slider, title: "Robot Speed", description: "Effective cycle time / speed", minValue: 1, maxValue: 5, step: 1, order: 5),
                ScoutingField(type: .multipleChoice, title: "Primary Strategy Focus", isRequired: true, options: ["Classifier", "Overflow", "Defense", "Mixed Play"], order: 6),
                ScoutingField(type: .boolean, title: "Defends Well", description: "Played effective defense", order: 7),
                ScoutingField(type: .number, title: "Penalties Received", description: "# of penalties committed", minValue: 0, maxValue: 10, order: 8),
                ScoutingField(type: .notes, title: "Teleop Notes", description: "Cycle paths, jams, mechanical issues", order: 9)
            ], order: 2),
            ScoutingSection(title: "Endgame (30 seconds)", fields: [
                ScoutingField(type: .boolean, title: "Final Artifacts Placed", description: "Additional artifacts during endgame", order: 0),
                ScoutingField(type: .number, title: "Additional Green Artifacts", description: "Green artifacts placed in endgame", minValue: 0, maxValue: 5, order: 1),
                ScoutingField(type: .number, title: "Additional Purple Artifacts", description: "Purple artifacts placed in endgame", minValue: 0, maxValue: 5, order: 2),
                ScoutingField(type: .boolean, title: "Robot Parked in Zone", description: "Robot successfully parked?", isRequired: true, order: 3),
                ScoutingField(type: .rating, title: "Endgame Execution", description: "Quality of endgame tasks", maxValue: 5, order: 4),
                ScoutingField(type: .notes, title: "Endgame Notes", description: "Any last-second strategy or mishaps", order: 5)
            ], order: 3),
            ScoutingSection(title: "Overall Assessment", fields: [
                ScoutingField(type: .slider, title: "Overall Team Quality", description: "Overall match performance rating", minValue: 1, maxValue: 5, step: 1, order: 0),
                ScoutingField(type: .slider, title: "Alliance Selection Rating", description: "Would you pick this team?", minValue: 1, maxValue: 5, step: 1, order: 1),
                ScoutingField(type: .multipleChoice, title: "Robot Reliability", isRequired: true, options: ["Very Reliable", "Mostly Reliable", "Occasional Issues", "Often Broken"], order: 2),
                ScoutingField(type: .boolean, title: "Earned Movement RP", description: "Movement RP achieved?", order: 3),
                ScoutingField(type: .boolean, title: "Earned Goal RP", description: "Goal RP achieved?", order: 4),
                ScoutingField(type: .boolean, title: "Earned Pattern RP", description: "Pattern RP achieved?", order: 5),
                ScoutingField(type: .notes, title: "Artifact Strategy Notes", description: "Classifier strategy, overflow funnels, etc.", order: 6),
                ScoutingField(type: .notes, title: "General Notes", description: "Mechanical strengths, weaknesses, upgrades", order: 7),
                ScoutingField(type: .notes, title: "Alliance Selection Notes", description: "Specific reasons to pick or avoid", order: 8)
            ], order: 4)
        ]
    }
}
