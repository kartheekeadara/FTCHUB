//
//  SeasonOperationsStores.swift
//  FTCHUB
//
//  Phase 3 — Season OS: local-first data (wishlist, sponsors, mentor hours, notebook, run log, rookie checklist).
//

import Foundation
import Combine

// MARK: - Parts wishlist

struct PartsWishlistLine: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var quantity: Int
    var estimatedUnitPrice: Decimal?
    
    init(id: UUID = UUID(), title: String, quantity: Int = 1, estimatedUnitPrice: Decimal? = nil) {
        self.id = id
        self.title = title
        self.quantity = max(1, quantity)
        self.estimatedUnitPrice = estimatedUnitPrice
    }
}

@MainActor
final class PartsWishlistStore: ObservableObject {
    @Published private(set) var lines: [PartsWishlistLine] = []
    private var teamId: UUID?
    
    func updateTeamContext(_ id: UUID?) {
        teamId = id
        reload()
    }
    
    private func key() -> String? {
        guard let teamId else { return nil }
        return "ftchub.season.wishlist.\(teamId.uuidString)"
    }
    
    func reload() {
        guard let key = key(),
              let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([PartsWishlistLine].self, from: data) else {
            lines = []
            return
        }
        lines = decoded
    }
    
    private func persist() {
        guard let key = key(), let data = try? JSONEncoder().encode(lines) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func addLine(title: String, quantity: Int, estimatedUnitPrice: Decimal?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lines.append(PartsWishlistLine(title: trimmed, quantity: quantity, estimatedUnitPrice: estimatedUnitPrice))
        persist()
    }
    
    func updateLine(_ line: PartsWishlistLine) {
        guard let idx = lines.firstIndex(where: { $0.id == line.id }) else { return }
        lines[idx] = line
        persist()
    }
    
    func removeLine(id: UUID) {
        lines.removeAll { $0.id == id }
        persist()
    }
    
    /// Plain-text block for pasting into an order note (Phase 3 wishlist → order).
    func exportNoteBlock() -> String {
        guard !lines.isEmpty else { return "" }
        var rows: [String] = ["— Parts wishlist —"]
        for line in lines {
            let price: String
            if let p = line.estimatedUnitPrice {
                let nf = NumberFormatter()
                nf.minimumFractionDigits = 0
                nf.maximumFractionDigits = 2
                nf.numberStyle = .decimal
                let s = nf.string(from: p as NSDecimalNumber) ?? "\(p as NSDecimalNumber)"
                price = " @ est. \(s) ea"
            } else {
                price = ""
            }
            rows.append("• \(line.title) × \(line.quantity)\(price)")
        }
        return rows.joined(separator: "\n")
    }
    
    /// Sum of lines that have estimated unit price; used to prefill order cost when creating an order from the wishlist.
    func estimatedTotalPrefillAmountString() -> String? {
        var total: Decimal = 0
        for line in lines {
            if let u = line.estimatedUnitPrice {
                total += u * Decimal(line.quantity)
            }
        }
        guard total > 0 else { return nil }
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.numberStyle = .decimal
        return f.string(from: total as NSDecimalNumber)
    }
}

// MARK: - Sponsor pipeline (CRM-lite)

struct SponsorPipelineEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var organizationName: String
    var stage: String
    var lastContactDate: Date?
    var pledgeAmount: Decimal?
    var notes: String
    
    init(
        id: UUID = UUID(),
        organizationName: String,
        stage: String = "Prospect",
        lastContactDate: Date? = nil,
        pledgeAmount: Decimal? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.organizationName = organizationName
        self.stage = stage
        self.lastContactDate = lastContactDate
        self.pledgeAmount = pledgeAmount
        self.notes = notes
    }
}

@MainActor
final class SponsorPipelineStore: ObservableObject {
    @Published private(set) var entries: [SponsorPipelineEntry] = []
    private var teamId: UUID?
    
    func updateTeamContext(_ id: UUID?) {
        teamId = id
        reload()
    }
    
    private func key() -> String? {
        guard let teamId else { return nil }
        return "ftchub.season.sponsors.\(teamId.uuidString)"
    }
    
    func reload() {
        guard let key = key(),
              let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SponsorPipelineEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded.sorted { ($0.lastContactDate ?? .distantPast) > ($1.lastContactDate ?? .distantPast) }
    }
    
    private func persist() {
        guard let key = key(), let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func upsert(_ entry: SponsorPipelineEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
    }
    
    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }
}

// MARK: - Mentor ledger

struct MentorLedgerEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var mentorName: String
    var hours: Double
    var date: Date
    var skillsNote: String
    
    init(id: UUID = UUID(), mentorName: String, hours: Double, date: Date = Date(), skillsNote: String = "") {
        self.id = id
        self.mentorName = mentorName
        self.hours = hours
        self.date = date
        self.skillsNote = skillsNote
    }
}

@MainActor
final class MentorLedgerStore: ObservableObject {
    @Published private(set) var entries: [MentorLedgerEntry] = []
    private var teamId: UUID?
    
    func updateTeamContext(_ id: UUID?) {
        teamId = id
        reload()
    }
    
    private func key() -> String? {
        guard let teamId else { return nil }
        return "ftchub.season.mentorHours.\(teamId.uuidString)"
    }
    
    func reload() {
        guard let key = key(),
              let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([MentorLedgerEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded.sorted { $0.date > $1.date }
    }
    
    private func persist() {
        guard let key = key(), let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func addEntry(_ entry: MentorLedgerEntry) {
        entries.insert(entry, at: 0)
        persist()
    }
    
    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }
    
    var totalHoursPast30Days: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.hours }
    }
}

// MARK: - Engineering notebook + run log

/// Entry type for engineering notes — aligns with FTC judging rubric categories.
enum EngineeringNoteKind: String, Codable, CaseIterable, Identifiable {
    case designDecision
    case testSession
    case bug
    case meeting
    case other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .designDecision: return "Design decision"
        case .testSession: return "Test session"
        case .bug: return "Bug / issue"
        case .meeting: return "Meeting notes"
        case .other: return "Other"
        }
    }
    
    var shortName: String {
        switch self {
        case .designDecision: return "Design"
        case .testSession: return "Test"
        case .bug: return "Bug"
        case .meeting: return "Meeting"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .designDecision: return "lightbulb"
        case .testSession: return "flask"
        case .bug: return "ladybug"
        case .meeting: return "person.3"
        case .other: return "doc.text"
        }
    }
    
    var templateTitle: String {
        switch self {
        case .designDecision: return "Design: "
        case .testSession: return "Test: "
        case .bug: return "Bug: "
        case .meeting: return "Meeting "
        case .other: return ""
        }
    }
    
    /// Guided prompts for the new-entry form (RECF-style design process).
    var entryGuidance: String {
        switch self {
        case .designDecision:
            return "State the problem and constraints, alternatives you considered, and why you chose this path. Summarize sketches or CAD in text if needed."
        case .testSession:
            return "Hypothesis, setup, expected vs actual, and evidence (numbers or a short summary of photos/video)."
        case .bug:
            return "Symptoms, when it happens, what you tried, and what you learned—even if the fix is still open."
        case .meeting:
            return "Decisions made, owners, and next actions so the team stays aligned."
        case .other:
            return "Keep entries chronological and student-authored; mentors guide, students document."
        }
    }
}

/// Engineering design process phase labels for notebook entries (FTC rubric alignment).
enum EngineeringDesignPhase: String, Codable, CaseIterable, Identifiable {
    case identifyPlan
    case createBuild
    case testEvaluate
    case iterateCommunicate
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .identifyPlan: return "Identify / plan"
        case .createBuild: return "Create / build"
        case .testEvaluate: return "Test / evaluate"
        case .iterateCommunicate: return "Iterate / communicate"
        }
    }
}

struct EngineeringNote: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var createdAt: Date
    
    // Extended fields (v2) — optional for backward compatibility
    var entryKind: EngineeringNoteKind
    var subsystem: String?
    var nextStep: String?
    
    // v3 — judging-aligned optional fields
    var authorStudent: String?
    var designPhase: EngineeringDesignPhase?
    var attachmentsNote: String?
    var linkedRunLogId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, createdAt, entryKind, subsystem, nextStep
        case authorStudent, designPhase, attachmentsNote, linkedRunLogId
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        createdAt: Date = Date(),
        entryKind: EngineeringNoteKind = .other,
        subsystem: String? = nil,
        nextStep: String? = nil,
        authorStudent: String? = nil,
        designPhase: EngineeringDesignPhase? = nil,
        attachmentsNote: String? = nil,
        linkedRunLogId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.entryKind = entryKind
        self.subsystem = subsystem
        self.nextStep = nextStep
        self.authorStudent = authorStudent
        self.designPhase = designPhase
        self.attachmentsNote = attachmentsNote
        self.linkedRunLogId = linkedRunLogId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        entryKind = try container.decodeIfPresent(EngineeringNoteKind.self, forKey: .entryKind) ?? .other
        subsystem = try container.decodeIfPresent(String.self, forKey: .subsystem)
        nextStep = try container.decodeIfPresent(String.self, forKey: .nextStep)
        authorStudent = try container.decodeIfPresent(String.self, forKey: .authorStudent)
        designPhase = try container.decodeIfPresent(EngineeringDesignPhase.self, forKey: .designPhase)
        attachmentsNote = try container.decodeIfPresent(String.self, forKey: .attachmentsNote)
        linkedRunLogId = try container.decodeIfPresent(UUID.self, forKey: .linkedRunLogId)
    }
}

struct RunLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var hypothesis: String
    var result: String
    var createdAt: Date
    
    // Extended fields (v2) — optional for backward compatibility
    var setup: String?
    var passFail: Bool?
    var nextAction: String?
    
    init(
        id: UUID = UUID(),
        hypothesis: String,
        result: String,
        createdAt: Date = Date(),
        setup: String? = nil,
        passFail: Bool? = nil,
        nextAction: String? = nil
    ) {
        self.id = id
        self.hypothesis = hypothesis
        self.result = result
        self.createdAt = createdAt
        self.setup = setup
        self.passFail = passFail
        self.nextAction = nextAction
    }
    
    // Custom decoder to handle legacy entries without new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        hypothesis = try container.decode(String.self, forKey: .hypothesis)
        result = try container.decode(String.self, forKey: .result)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        setup = try container.decodeIfPresent(String.self, forKey: .setup)
        passFail = try container.decodeIfPresent(Bool.self, forKey: .passFail)
        nextAction = try container.decodeIfPresent(String.self, forKey: .nextAction)
    }
}

/// Local self-assessment checklist (not official judging).
struct EngineeringRubricChecklist: Codable, Equatable {
    var problemClear: Bool = false
    var alternativesConsidered: Bool = false
    var testEvidenceDocumented: Bool = false
    var failuresAndPivots: Bool = false
    var studentVoice: Bool = false
    var iterationVisible: Bool = false
}

@MainActor
final class EngineeringNotebookStore: ObservableObject {
    @Published private(set) var notes: [EngineeringNote] = []
    @Published private(set) var runs: [RunLogEntry] = []
    @Published var rubricChecklist = EngineeringRubricChecklist()
    private var teamId: UUID?
    
    func updateTeamContext(_ id: UUID?) {
        teamId = id
        reload()
    }
    
    private func notesKey() -> String? {
        guard let teamId else { return nil }
        return "ftchub.season.engineeringNotes.\(teamId.uuidString)"
    }
    
    private func runsKey() -> String? {
        guard let teamId else { return nil }
        return "ftchub.season.runLog.\(teamId.uuidString)"
    }
    
    private func rubricKey() -> String? {
        guard let teamId else { return nil }
        return "ftchub.season.engineeringRubric.\(teamId.uuidString)"
    }
    
    func reload() {
        if let k = notesKey(), let data = UserDefaults.standard.data(forKey: k),
           let decoded = try? JSONDecoder().decode([EngineeringNote].self, from: data) {
            notes = decoded.sorted { $0.createdAt > $1.createdAt }
        } else {
            notes = []
        }
        if let k = runsKey(), let data = UserDefaults.standard.data(forKey: k),
           let decoded = try? JSONDecoder().decode([RunLogEntry].self, from: data) {
            runs = decoded.sorted { $0.createdAt > $1.createdAt }
        } else {
            runs = []
        }
        if let k = rubricKey(), let data = UserDefaults.standard.data(forKey: k),
           let decoded = try? JSONDecoder().decode(EngineeringRubricChecklist.self, from: data) {
            rubricChecklist = decoded
        } else {
            rubricChecklist = EngineeringRubricChecklist()
        }
    }
    
    private func persistNotes() {
        guard let k = notesKey(), let data = try? JSONEncoder().encode(notes) else { return }
        UserDefaults.standard.set(data, forKey: k)
    }
    
    private func persistRuns() {
        guard let k = runsKey(), let data = try? JSONEncoder().encode(runs) else { return }
        UserDefaults.standard.set(data, forKey: k)
    }
    
    func addNote(_ note: EngineeringNote) {
        notes.insert(note, at: 0)
        persistNotes()
    }
    
    func updateNote(_ note: EngineeringNote) {
        guard let i = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[i] = note
        persistNotes()
    }
    
    func setRubricChecklist(_ checklist: EngineeringRubricChecklist) {
        rubricChecklist = checklist
        guard let k = rubricKey(), let data = try? JSONEncoder().encode(checklist) else { return }
        UserDefaults.standard.set(data, forKey: k)
    }
    
    func addRun(_ run: RunLogEntry) {
        runs.insert(run, at: 0)
        persistRuns()
    }
    
    func removeNote(id: UUID) {
        notes.removeAll { $0.id == id }
        persistNotes()
    }
    
    func removeRun(id: UUID) {
        runs.removeAll { $0.id == id }
        persistRuns()
    }
}

// MARK: - Rookie playbook (checklist persistence)

struct RookiePlaybookTask: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let learnMoreURL: URL?
}

enum RookiePlaybook {
    static let tasks: [RookiePlaybookTask] = [
        RookiePlaybookTask(
            id: "register",
            title: "Confirm team registration & payment",
            detail: "Double-check roster size and payment status in FIRST dashboards.",
            learnMoreURL: URL(string: "https://www.firstinspires.org/resource-library/ftc/team-management-resources")
        ),
        RookiePlaybookTask(
            id: "ypp",
            title: "Screen mentors (YPP)",
            detail: "Ensure two-deep leadership is possible for meetings and travel.",
            learnMoreURL: URL(string: "https://www.firstinspires.org/resource-library/youth-protection-programming")
        ),
        RookiePlaybookTask(
            id: "bank",
            title: "Open team financial workflow",
            detail: "Align on how orders and receipts flow through your school or booster org.",
            learnMoreURL: URL(string: "https://www.firstinspires.org/resource-library/ftc/fundraising-resources")
        ),
        RookiePlaybookTask(
            id: "robot_scope",
            title: "Lock a minimum viable robot scope",
            detail: "Pick one scoring path you can iterate on before adding complexity.",
            learnMoreURL: URL(string: "https://www.firstinspires.org/robotics/ftc/game-and-season")
        ),
        RookiePlaybookTask(
            id: "meeting_cadence",
            title: "Set a weekly build cadence",
            detail: "Put recurring meetings on the calendar and assign a student lead.",
            learnMoreURL: nil
        ),
        RookiePlaybookTask(
            id: "parts_order",
            title: "Place first parts order",
            detail: "Use wishlist → order in Season workspace, then tie to a budget line.",
            learnMoreURL: nil
        ),
        RookiePlaybookTask(
            id: "scout_template",
            title: "Agree on one scouting template",
            detail: "Keep fields consistent so alliance prep stays trustworthy.",
            learnMoreURL: nil
        ),
        RookiePlaybookTask(
            id: "safety",
            title: "Run tool & field safety talk",
            detail: "Document who is certified for power tools and pit safety.",
            learnMoreURL: URL(string: "https://www.firstinspires.org/robotics/ftc/game-and-season")
        )
    ]
    
    static func storageKey(teamId: UUID) -> String {
        "ftchub.season.rookieDone.\(teamId.uuidString)"
    }
    
    static func completedIds(for teamId: UUID) -> Set<String> {
        guard let arr = UserDefaults.standard.array(forKey: storageKey(teamId: teamId)) as? [String] else {
            return []
        }
        return Set(arr)
    }
    
    static func setCompleted(_ ids: Set<String>, teamId: UUID) {
        UserDefaults.standard.set(Array(ids), forKey: storageKey(teamId: teamId))
    }
}

// MARK: - Grant radar (static windows + official links)

struct GrantRadarItem: Identifiable {
    let id: String
    let title: String
    let windowDescription: String
    let url: URL
}

enum GrantRadar {
    static let items: [GrantRadarItem] = [
        GrantRadarItem(
            id: "first-fundraising",
            title: "FIRST fundraising hub",
            windowDescription: "Grant and fundraising options update each season — bookmark the official hub.",
            url: URL(string: "https://www.firstinspires.org/resource-library/ftc/fundraising-resources")!
        ),
        GrantRadarItem(
            id: "first-team-mgmt",
            title: "Team management checklist",
            windowDescription: "Registration, roster, and season logistics from FIRST.",
            url: URL(string: "https://www.firstinspires.org/resource-library/ftc/team-management-resources")!
        )
    ]
}
