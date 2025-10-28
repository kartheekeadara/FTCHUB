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
        let formData = ScoutingFormData()
        var template = ScoutingTemplate(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            name: "DECODE Match Scouting - 2025-2026",
            description: "Standard scouting form for FTC DECODE matches",
            isDefault: true,
            templateData: formData,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Add DECODE-specific sections with green/purple artifact tracking
        template.templateData.sections = [
            ScoutingSection(title: "Pre-Match", fields: [
                ScoutingField(type: .boolean, title: "Robot Visible Before Match", description: "Was robot present at inspection?"),
                ScoutingField(type: .multipleChoice, title: "Alliance Color", isRequired: true, options: ["Red", "Blue"]),
                ScoutingField(type: .notes, title: "Pre-Match Notes", description: "Any observations before match starts")
            ], order: 0),
            
            ScoutingSection(title: "Autonomous (30 seconds)", fields: [
                ScoutingField(type: .boolean, title: "Green Artifacts Scored", description: "Did robot score green artifacts?"),
                ScoutingField(type: .number, title: "Green Artifacts in Correct Zones", description: "Green artifacts in proper zones", minValue: 0, maxValue: 10),
                ScoutingField(type: .boolean, title: "Purple Artifacts Scored", description: "Did robot score purple artifacts?"),
                ScoutingField(type: .number, title: "Purple Artifacts in Correct Zones", description: "Purple artifacts in proper zones", minValue: 0, maxValue: 10),
                ScoutingField(type: .rating, title: "Autonomous Reliability", description: "How consistent is their auto?", maxValue: 5)
            ], order: 1),
            
            ScoutingSection(title: "Teleop (120 seconds)", fields: [
                ScoutingField(type: .number, title: "Green Artifacts Placed", description: "Total green artifacts scored in teleop", minValue: 0, maxValue: 50),
                ScoutingField(type: .number, title: "Purple Artifacts Placed", description: "Total purple artifacts scored in teleop", minValue: 0, maxValue: 50),
                ScoutingField(type: .boolean, title: "Alliance Coordination", description: "Did team coordinate with alliance partner?"),
                ScoutingField(type: .slider, title: "Driving Quality", description: "Rate the driver's skill", minValue: 1, maxValue: 5, step: 1),
                ScoutingField(type: .slider, title: "Robot Speed", description: "How fast is their robot?", minValue: 1, maxValue: 5, step: 1),
                ScoutingField(type: .multipleChoice, title: "Primary Strategy", isRequired: true, options: ["Offensive Scoring", "Defensive", "Mixed", "Artifact Collection"]),
                ScoutingField(type: .boolean, title: "Defends Well", description: "Does this team play defense?"),
                ScoutingField(type: .number, title: "Penalties Received", description: "Number of penalties earned", minValue: 0, maxValue: 10)
            ], order: 2),
            
            ScoutingSection(title: "Endgame (30 seconds)", fields: [
                ScoutingField(type: .boolean, title: "Final Artifacts Placed", description: "Did robot place additional artifacts in endgame?"),
                ScoutingField(type: .number, title: "Additional Green Artifacts", description: "Green artifacts in endgame", minValue: 0, maxValue: 5),
                ScoutingField(type: .number, title: "Additional Purple Artifacts", description: "Purple artifacts in endgame", minValue: 0, maxValue: 5),
                ScoutingField(type: .boolean, title: "Robot Parked in Zone", description: "Did robot park in designated zone?", isRequired: true),
                ScoutingField(type: .rating, title: "Endgame Execution", description: "How well did they execute endgame?", maxValue: 5)
            ], order: 3),
            
            ScoutingSection(title: "Overall Assessment", fields: [
                ScoutingField(type: .slider, title: "Overall Team Quality", description: "Overall ranking of team", minValue: 1, maxValue: 5, step: 1),
                ScoutingField(type: .slider, title: "Alliance Selection Rating", description: "Would you pick this team?", minValue: 1, maxValue: 5, step: 1),
                ScoutingField(type: .multipleChoice, title: "Robot Reliability", isRequired: true, options: ["Very Reliable", "Mostly Reliable", "Sometimes Broken", "Often Broken"]),
                ScoutingField(type: .notes, title: "Artifact Strategy Notes", description: "How effective was their artifact strategy?"),
                ScoutingField(type: .notes, title: "General Notes", description: "Additional observations, strategies observed, strengths/weaknesses"),
                ScoutingField(type: .notes, title: "Alliance Selection Notes", description: "Specific reasons to pick or avoid this team")
            ], order: 4)
        ]
        
        return template
    }
}
