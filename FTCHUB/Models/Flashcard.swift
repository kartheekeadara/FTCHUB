//
//  Flashcard.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import Foundation

// MARK: - Flashcard
struct Flashcard: Identifiable, Codable {
    let id: UUID
    let front: String
    let back: String
    let category: String
    let difficulty: DifficultyLevel
    var lastReviewed: Date?
    var reviewCount: Int
    var nextReviewDate: Date?
    var easeFactor: Double // For spaced repetition algorithm
    
    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        category: String,
        difficulty: DifficultyLevel = .beginner,
        lastReviewed: Date? = nil,
        reviewCount: Int = 0,
        nextReviewDate: Date? = nil,
        easeFactor: Double = 2.5
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.category = category
        self.difficulty = difficulty
        self.lastReviewed = lastReviewed
        self.reviewCount = reviewCount
        self.nextReviewDate = nextReviewDate
        self.easeFactor = easeFactor
    }
    
    var isDue: Bool {
        guard let nextReview = nextReviewDate else { return true }
        return Date() >= nextReview
    }
}

// MARK: - Flashcard Deck
struct FlashcardDeck: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: ResourceCategory
    let icon: String
    var flashcards: [Flashcard]
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: ResourceCategory,
        icon: String,
        flashcards: [Flashcard] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.icon = icon
        self.flashcards = flashcards
    }
    
    var dueCards: [Flashcard] {
        flashcards.filter { $0.isDue }
    }
    
    var masteredCards: [Flashcard] {
        flashcards.filter { $0.reviewCount >= 5 }
    }
}

// MARK: - Spaced Repetition Algorithm
struct SpacedRepetition {
    static func calculateNextReview(
        card: Flashcard,
        quality: Int // 0-5: 0=forgot, 1=hard, 2=medium, 3=good, 4=easy, 5=perfect
    ) -> (nextReviewDate: Date, newEaseFactor: Double) {
        var newEaseFactor = card.easeFactor
        
        // Update ease factor based on quality
        newEaseFactor = max(1.3, newEaseFactor + (0.1 - (5.0 - Double(quality)) * (0.08 + (5.0 - Double(quality)) * 0.02)))
        
        // Calculate interval
        var interval: Int
        if card.reviewCount == 0 {
            interval = 1 // First review: next day
        } else if card.reviewCount == 1 {
            interval = 6 // Second review: 6 days
        } else {
            interval = Int(Double(card.reviewCount) * newEaseFactor)
        }
        
        // Adjust based on quality
        switch quality {
        case 0, 1: // Forgot or hard - reset
            interval = 1
        case 2: // Medium - reduce interval
            interval = max(1, interval / 2)
        case 3, 4, 5: // Good, easy, perfect - use calculated interval
            break
        default:
            break
        }
        
        let nextReview = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
        return (nextReview, newEaseFactor)
    }
}

