//
//  NotesManager.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import Foundation
import Combine

class NotesManager: ObservableObject {
    static let shared = NotesManager()
    
    @Published private(set) var notes: [UUID: String] = [:]
    
    private let notesKey = "learning_notes"
    
    private init() {
        loadNotes()
    }
    
    // MARK: - Notes Management
    func getNote(for id: UUID) -> String {
        notes[id] ?? ""
    }
    
    func setNote(_ note: String, for id: UUID) {
        if note.isEmpty {
            notes.removeValue(forKey: id)
        } else {
            notes[id] = note
        }
        saveNotes()
    }
    
    func hasNote(for id: UUID) -> Bool {
        notes[id] != nil && !notes[id]!.isEmpty
    }
    
    func deleteNote(for id: UUID) {
        notes.removeValue(forKey: id)
        saveNotes()
    }
    
    // MARK: - Persistence
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            notes = Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in
                guard let uuid = UUID(uuidString: key) else { return nil }
                return (uuid, value)
            })
        }
    }
    
    private func saveNotes() {
        let stringKeys = Dictionary(uniqueKeysWithValues: notes.map { ($0.key.uuidString, $0.value) })
        if let data = try? JSONEncoder().encode(stringKeys) {
            UserDefaults.standard.set(data, forKey: notesKey)
        }
    }
}

