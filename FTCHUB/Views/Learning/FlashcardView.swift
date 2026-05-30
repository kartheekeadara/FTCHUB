//
//  FlashcardView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct FlashcardView: View {
    let deck: FlashcardDeck
    @StateObject private var flashcardManager = FlashcardManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentCardIndex = 0
    @State private var isFlipped = false
    @State private var showingResult = false
    @State private var reviewQuality: Int?
    
    private var currentCard: Flashcard? {
        guard currentCardIndex < deck.flashcards.count else { return nil }
        return deck.flashcards[currentCardIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showingResult {
                    reviewResultView
                } else if let card = currentCard {
                    flashcardContent(card: card)
                } else {
                    emptyStateView
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(deck.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Flashcard Content
    @ViewBuilder
    private func flashcardContent(card: Flashcard) -> some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressIndicator
            
            Spacer()
            
            // Card
            GeometryReader { geometry in
                ZStack {
                    // Front of card (Question)
                    cardFace(
                        label: "Question",
                        text: card.front,
                        showHint: true
                    )
                    .rotation3DEffect(
                        .degrees(isFlipped ? 90 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .opacity(isFlipped ? 0 : 1)
                    
                    // Back of card (Answer) - start at -90 degrees to prevent mirroring
                    cardFace(
                        label: "Answer",
                        text: card.back,
                        showHint: false
                    )
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -90),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .opacity(isFlipped ? 1 : 0)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isFlipped.toggle()
                    }
                    DesignSystem.Haptics.selection()
                }
            }
            .padding()
            .aspectRatio(0.7, contentMode: .fit)
            
            Spacer()
            
            // Quality buttons (shown when flipped)
            if isFlipped {
                qualityButtons
            }
        }
    }
    
    // MARK: - Card Face
    @ViewBuilder
    private func cardFace(label: String, text: String, showHint: Bool) -> some View {
        let deckColor = LearningModule.defaultColor(for: deck.category)
        
        ZStack {
            // Card background with gradient
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.cardBackground,
                            deckColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    deckColor.opacity(0.3),
                                    deckColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: deckColor.opacity(0.15), radius: 25, x: 0, y: 12)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 15, x: 0, y: 6)
            
            // Card content
            VStack(spacing: 24) {
                // Side indicator with gradient
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: label == "Question" ? "questionmark.circle.fill" : "checkmark.circle.fill")
                            .font(.caption2)
                        Text(label)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(deckColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(deckColor.opacity(0.12))
                    )
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Card text with better typography
                VStack(spacing: 12) {
                    Text(text)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Flip hint with icon
                if showHint {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption2)
                        Text("Tap to reveal answer")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(deckColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(deckColor.opacity(0.1))
                    )
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        let deckColor = LearningModule.defaultColor(for: deck.category)
        let progress = CGFloat(currentCardIndex + 1) / CGFloat(deck.flashcards.count)
        
        return VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.caption)
                        .foregroundColor(deckColor)
                    Text("Card \(currentCardIndex + 1) of \(deck.flashcards.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(deckColor)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 6)
                    
                    // Progress fill with gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    deckColor,
                                    deckColor.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progress,
                            height: 6
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.secondaryBackground)
        .overlay(
            Rectangle()
                .fill(Color.clear)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Quality Buttons
    private var qualityButtons: some View {
        let deckColor = LearningModule.defaultColor(for: deck.category)
        
        return VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(deckColor)
                Text("How well did you know this?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            HStack(spacing: 10) {
                QualityButton(quality: 0, label: "Forgot", color: .red, deckColor: deckColor) {
                    submitQuality(0)
                }
                QualityButton(quality: 1, label: "Hard", color: .orange, deckColor: deckColor) {
                    submitQuality(1)
                }
                QualityButton(quality: 2, label: "Medium", color: .yellow, deckColor: deckColor) {
                    submitQuality(2)
                }
                QualityButton(quality: 3, label: "Good", color: .green, deckColor: deckColor) {
                    submitQuality(3)
                }
                QualityButton(quality: 4, label: "Easy", color: .blue, deckColor: deckColor) {
                    submitQuality(4)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(Color.clear)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.md)
    }
    
    // MARK: - Review Result View
    private var reviewResultView: some View {
        let deckColor = LearningModule.defaultColor(for: deck.category)
        
        return VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                deckColor.opacity(0.2),
                                deckColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [deckColor, deckColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Review Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("You've reviewed \(currentCardIndex) cards")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [deckColor, deckColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(DesignSystem.CornerRadius.md)
                .shadow(color: deckColor.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        let deckColor = LearningModule.defaultColor(for: deck.category)
        
        return VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                deckColor.opacity(0.15),
                                deckColor.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(deckColor)
            }
            
            VStack(spacing: 8) {
                Text("No cards to review")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("All cards have been reviewed. Check back later!")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
    
    // MARK: - Actions
    private func submitQuality(_ quality: Int) {
        guard let card = currentCard else { return }
        
        flashcardManager.updateFlashcard(card, in: deck.id, quality: quality)
        DesignSystem.Haptics.selection()
        
        // Move to next card
        if currentCardIndex < deck.flashcards.count - 1 {
            withAnimation {
                currentCardIndex += 1
                isFlipped = false
            }
        } else {
            showingResult = true
        }
    }
}

// MARK: - Quality Button
struct QualityButton: View {
    let quality: Int
    let label: String
    let color: Color
    let deckColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Text("\(quality)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.15),
                                color.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(color.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: color.opacity(0.2), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flashcard Deck List View
struct FlashcardDeckListView: View {
    @StateObject private var flashcardManager = FlashcardManager.shared
    @State private var selectedDeck: FlashcardDeck?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(flashcardManager.decks) { deck in
                    FlashcardDeckCard(deck: deck) {
                        selectedDeck = deck
                    }
                }
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedDeck) { deck in
            FlashcardView(deck: deck)
        }
    }
}

// MARK: - Flashcard Deck Card
struct FlashcardDeckCard: View {
    let deck: FlashcardDeck
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var deckColor: Color {
        LearningModule.defaultColor(for: deck.category)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [
                                    deckColor.opacity(0.2),
                                    deckColor.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(deckColor.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Image(systemName: deck.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [deckColor, deckColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 10) {
                    Text(deck.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(deck.description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        // Card count with better styling
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.caption)
                                .foregroundColor(deckColor)
                            Text("\(deck.flashcards.count) cards")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(deckColor.opacity(0.1))
                        )
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(deckColor.opacity(0.6))
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                DesignSystem.Colors.cardBackground
                    .shadow(color: deckColor.opacity(0.1), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [
                                deckColor.opacity(0.3),
                                deckColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flashcard Deck Selection View
struct FlashcardDeckSelectionView: View {
    let decks: [FlashcardDeck]
    @State private var selectedDeck: FlashcardDeck?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if decks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No flashcards available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(decks) { deck in
                        FlashcardDeckCard(deck: deck) {
                            selectedDeck = deck
                        }
                    }
                }
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Study Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(item: $selectedDeck) { deck in
            FlashcardView(deck: deck)
        }
    }
}

