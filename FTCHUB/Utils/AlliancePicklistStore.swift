//
//  AlliancePicklistStore.swift
//  FTCHUB
//
//  Alliance selection shortlist: team numbers, notes, flags, order — local-first per team.
//

import Foundation
import Combine

struct AlliancePicklistEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var teamNumber: String
    var notes: String
    var isRedFlag: Bool
    /// Lower sorts first (top of list).
    var sortIndex: Int
    
    init(
        id: UUID = UUID(),
        teamNumber: String,
        notes: String = "",
        isRedFlag: Bool = false,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.teamNumber = teamNumber
        self.notes = notes
        self.isRedFlag = isRedFlag
        self.sortIndex = sortIndex
    }
}

@MainActor
final class AlliancePicklistStore: ObservableObject {
    @Published private(set) var entries: [AlliancePicklistEntry] = []
    private var teamId: UUID?
    
    func updateTeamContext(_ id: UUID?) {
        guard teamId != id else { return }
        teamId = id
        reload()
    }
    
    private func storageKey() -> String? {
        guard let teamId else { return nil }
        return "ftchub.strategy.alliancePicklist.\(teamId.uuidString)"
    }
    
    func reload() {
        guard let key = storageKey(),
              let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([AlliancePicklistEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded.sorted { $0.sortIndex < $1.sortIndex }
    }
    
    private func persist() {
        guard let key = storageKey(), let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func renumber() {
        for i in entries.indices {
            entries[i].sortIndex = i
        }
    }
    
    func add(teamNumber raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let next = (entries.map(\.sortIndex).max() ?? -1) + 1
        let entry = AlliancePicklistEntry(teamNumber: trimmed, sortIndex: next)
        entries.append(entry)
        renumber()
        persist()
    }
    
    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        renumber()
        persist()
    }
    
    func update(_ entry: AlliancePicklistEntry) {
        guard let i = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[i] = entry
        persist()
    }
    
    func move(from source: IndexSet, to destination: Int) {
        var sorted = entries.sorted { $0.sortIndex < $1.sortIndex }
        let itemsToMove = source.sorted().map { sorted[$0] }
        for i in source.sorted(by: >) {
            sorted.remove(at: i)
        }
        var target = destination
        for i in source where i < destination {
            target -= 1
        }
        for (offset, item) in itemsToMove.enumerated() {
            sorted.insert(item, at: target + offset)
        }
        entries = sorted
        renumber()
        persist()
    }
    
    /// Reorders entries to match the given id order (e.g. after List `.onMove`).
    func applyOrder(ids: [UUID]) {
        for (i, id) in ids.enumerated() {
            guard let idx = entries.firstIndex(where: { $0.id == id }) else { continue }
            entries[idx].sortIndex = i
        }
        entries.sort { $0.sortIndex < $1.sortIndex }
        persist()
    }
    
    func moveEntry(id: UUID, direction: Int) {
        guard let i = entries.firstIndex(where: { $0.id == id }) else { return }
        let j = i + direction
        guard entries.indices.contains(j) else { return }
        entries.swapAt(i, j)
        renumber()
        persist()
    }
    
    func exportPlainText(teamNumber: String?) -> String {
        var lines: [String] = ["— FTCHUB alliance pick list —"]
        if let t = teamNumber, !t.isEmpty {
            lines.append("Captain / team: \(t)")
        }
        lines.append("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))")
        lines.append("")
        if entries.isEmpty {
            lines.append("(empty)")
        } else {
            for (idx, e) in entries.sorted(by: { $0.sortIndex < $1.sortIndex }).enumerated() {
                let flag = e.isRedFlag ? " [!]" : ""
                lines.append("\(idx + 1). \(e.teamNumber)\(flag)")
                if !e.notes.isEmpty {
                    lines.append("   Notes: \(e.notes)")
                }
            }
        }
        lines.append("")
        lines.append("Data from your scouting only — verify on the field.")
        return lines.joined(separator: "\n")
    }
    
    func exportCSV() -> String {
        var rows = ["rank,team_number,red_flag,notes"]
        for (idx, e) in entries.sorted(by: { $0.sortIndex < $1.sortIndex }).enumerated() {
            let flag = e.isRedFlag ? "1" : "0"
            let safeNotes = e.notes.replacingOccurrences(of: "\"", with: "'").replacingOccurrences(of: "\n", with: " ")
            rows.append("\(idx + 1),\"\(e.teamNumber)\",\(flag),\"\(safeNotes)\"")
        }
        return rows.joined(separator: "\n")
    }
}
