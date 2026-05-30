//
//  FlashcardManager.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import Foundation
import Combine

class FlashcardManager: ObservableObject {
    static let shared = FlashcardManager()
    
    @Published private(set) var decks: [FlashcardDeck] = []
    
    private let decksKey = "flashcard_decks"
    
    private init() {
        loadDecks()
        // Always ensure we have the latest default decks
        let defaultDecks = FlashcardData.defaultDecks
        let defaultDecksCount = defaultDecks.count
        
        if decks.isEmpty {
            // First time - load all defaults
            decks = defaultDecks
            saveDecks()
        } else if decks.count < defaultDecksCount {
            // We have fewer decks than defaults - merge new ones
            let existingDeckIds = Set(decks.map { $0.id })
            let newDecks = defaultDecks.filter { !existingDeckIds.contains($0.id) }
            decks.append(contentsOf: newDecks)
            saveDecks()
        } else {
            // Check if any default decks are missing by title (in case IDs changed)
            let existingTitles = Set(decks.map { $0.title })
            let missingDecks = defaultDecks.filter { !existingTitles.contains($0.title) }
            if !missingDecks.isEmpty {
                decks.append(contentsOf: missingDecks)
                saveDecks()
            }
        }
    }
    
    // MARK: - Deck Management
    func getDeck(id: UUID) -> FlashcardDeck? {
        decks.first { $0.id == id }
    }
    
    func addDeck(_ deck: FlashcardDeck) {
        decks.append(deck)
        saveDecks()
    }
    
    func updateDeck(_ deck: FlashcardDeck) {
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[index] = deck
            saveDecks()
        }
    }
    
    func deleteDeck(_ deckId: UUID) {
        decks.removeAll { $0.id == deckId }
        saveDecks()
    }
    
    // MARK: - Flashcard Management
    func updateFlashcard(_ flashcard: Flashcard, in deckId: UUID, quality: Int) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckId }),
              let cardIndex = decks[deckIndex].flashcards.firstIndex(where: { $0.id == flashcard.id }) else {
            return
        }
        
        let (nextReview, newEaseFactor) = SpacedRepetition.calculateNextReview(card: flashcard, quality: quality)
        
        var updatedCard = flashcard
        updatedCard.lastReviewed = Date()
        updatedCard.reviewCount += 1
        updatedCard.nextReviewDate = nextReview
        updatedCard.easeFactor = newEaseFactor
        
        decks[deckIndex].flashcards[cardIndex] = updatedCard
        saveDecks()
    }
    
    // MARK: - Default Decks
    private func loadDefaultDecks() {
        decks = FlashcardData.defaultDecks
        saveDecks()
    }
    
    // MARK: - Persistence
    private func loadDecks() {
        if let data = UserDefaults.standard.data(forKey: decksKey),
           let decoded = try? JSONDecoder().decode([FlashcardDeckData].self, from: data) {
            decks = decoded.map { $0.toFlashcardDeck() }
        }
    }
    
    private func saveDecks() {
        let data = decks.map { FlashcardDeckData(from: $0) }
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: decksKey)
        }
    }
}

// MARK: - Flashcard Deck Data (for Codable)
struct FlashcardDeckData: Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let icon: String
    let flashcards: [Flashcard]
    
    init(from deck: FlashcardDeck) {
        self.id = deck.id.uuidString
        self.title = deck.title
        self.description = deck.description
        self.category = deck.category.rawValue
        self.icon = deck.icon
        self.flashcards = deck.flashcards
    }
    
    func toFlashcardDeck() -> FlashcardDeck {
        FlashcardDeck(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            description: description,
            category: ResourceCategory(rawValue: category) ?? .technical,
            icon: icon,
            flashcards: flashcards
        )
    }
}

// MARK: - ResourceCategory Extension
extension ResourceCategory {
    var rawValue: String {
        switch self {
        case .official: return "official"
        case .rules: return "rules"
        case .community: return "community"
        case .technical: return "technical"
        case .programming: return "programming"
        case .strategy: return "strategy"
        case .safety: return "safety"
        case .awards: return "awards"
        case .video: return "video"
        case .parts: return "parts"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "official": self = .official
        case "rules": self = .rules
        case "community": self = .community
        case "technical": self = .technical
        case "programming": self = .programming
        case "strategy": self = .strategy
        case "safety": self = .safety
        case "awards": self = .awards
        case "video": self = .video
        case "parts": self = .parts
        default: return nil
        }
    }
}

