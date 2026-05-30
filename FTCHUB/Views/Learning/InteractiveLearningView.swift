//
//  InteractiveLearningView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct InteractiveLearningView: View {
    var usesGuestLayout: Bool = false
    
    @State private var modules: [LearningModule] = []
    @StateObject private var flashcardManager = FlashcardManager.shared
    @ObservedObject private var learningProgress = LearningProgressManager.shared
    @State private var selectedCategory: String? = nil
    
    private var cardMinHeight: CGFloat {
        usesGuestLayout ? 92 : 76
    }
    
    private var resumeModule: LearningModule? {
        let catalog = modules.isEmpty ? LearningModuleData.allModules : modules
        return learningProgress.resumeCandidate(from: catalog)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let module = resumeModule {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONTINUE LEARNING")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .tracking(0.5)
                            .padding(.horizontal, 20)

                        NavigationLink(destination: LearningModuleView(module: module)) {
                            HStack(spacing: 0) {
                                // 3pt orange left strip
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(DesignSystem.Colors.primary)
                                    .frame(width: 3)
                                    .padding(.vertical, 12)
                                    .padding(.trailing, 14)

                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.Colors.primary.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(DesignSystem.Colors.primary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(module.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        Text(module.description)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                                .padding(.vertical, 16)
                                .padding(.trailing, 16)
                            }
                            .background(DesignSystem.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                
                // Flashcards Section
                if !flashcardManager.decks.isEmpty {
                    flashcardsSection
                }
                
                // Modules Grid with modern card design
                if modules.isEmpty {
                    emptyStateView
                } else {
                    modulesGrid
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .tabBarScrollInset()
        .background(
            ZStack {
                // Subtle gradient background
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.background,
                        DesignSystem.Colors.background.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Decorative elements (must not participate in hit testing — can extend past scroll bounds)
                GeometryReader { geometry in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.03),
                                    Color.clear
                                ],
                                center: .topTrailing,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.8
                            )
                        )
                        .frame(width: geometry.size.width * 1.2, height: geometry.size.width * 1.2)
                        .offset(x: geometry.size.width * 0.3, y: -geometry.size.width * 0.2)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignSystem.Colors.accent.opacity(0.02),
                                    Color.clear
                                ],
                                center: .bottomLeading,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.6
                            )
                        )
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.9)
                        .offset(x: -geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                }
                .allowsHitTesting(false)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        )
        .task {
            if modules.isEmpty {
                await loadModules()
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Large icon with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.15),
                                    DesignSystem.Colors.accent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary,
                                    DesignSystem.Colors.accent
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Learn FTC")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Master concepts through interactive learning")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(
            // Subtle top border effect
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.primary.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                Spacer()
            }
        )
    }
    
    // MARK: - Flashcards Section
    private var flashcardsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text("Flashcard Decks")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Text("\(flashcardManager.decks.reduce(0) { $0 + $1.flashcards.count })")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignSystem.Colors.primary,
                                                DesignSystem.Colors.accent
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    Text("Spaced repetition — tap a deck to study")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)

            LazyVStack(spacing: 10) {
                ForEach(flashcardManager.decks) { deck in
                    NavigationLink(destination: FlashcardView(deck: deck)) {
                        ModernFlashcardCard(deck: deck, minHeight: cardMinHeight)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Modules Grid
    private var modulesGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Modules")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Interactive tutorials and guides")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 16)
            
            // Modules with modern card design
            LazyVStack(spacing: 8) { // Small vertical gap
                ForEach(modules) { module in
                    NavigationLink(destination: LearningModuleView(module: module)) {
                        ModernModuleCard(module: module, minHeight: cardMinHeight)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.primary.opacity(0.1),
                                DesignSystem.Colors.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.primary.opacity(0.6),
                                DesignSystem.Colors.accent.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("No modules available")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Learning modules will appear here soon")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    // MARK: - Load Modules
    private func loadModules() async {
        modules = LearningModuleData.allModules
    }
}

// MARK: - Filter Chip
struct LearningFilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(isActive ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(isActive ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.secondaryBackground)
        )
    }
}

// MARK: - Modern Flashcard Card (full-width list row)
struct ModernFlashcardCard: View {
    let deck: FlashcardDeck
    var minHeight: CGFloat = 76
    
    private var deckColor: Color {
        LearningModule.defaultColor(for: deck.category)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(deckColor.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: deck.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(deckColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(deck.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(deck.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(deck.flashcards.count)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(DesignSystem.Colors.tertiaryBackground)
                .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(minHeight: minHeight)
        .padding(16)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.12), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Modern Module Card
struct ModernModuleCard: View {
    let module: LearningModule
    var minHeight: CGFloat = 76
    @StateObject private var progressManager = LearningProgressManager.shared
    
    private var moduleColor: Color {
        LearningModule.defaultColor(for: module.category)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Content
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(moduleColor.opacity(0.10))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: module.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(moduleColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(module.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if progressManager.isModuleCompleted(module.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(module.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    
                    // Progress indicator
                    let completionPercentage = progressManager.getCompletionPercentage(for: module)
                    if completionPercentage > 0 {
                        HStack(spacing: 6) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(DesignSystem.Colors.border.opacity(0.2))
                                        .frame(height: 3)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(moduleColor)
                                        .frame(width: geometry.size.width * completionPercentage, height: 3)
                                }
                            }
                            .frame(height: 3)
                            
                            Text("\(Int(completionPercentage * 100))%")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(moduleColor)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(16)
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
        )
    }
}
