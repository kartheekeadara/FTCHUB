//
//  AchievementView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct AchievementView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedCategory: AchievementCategory?
    
    private var achievements: [Achievement] {
        AchievementData.allAchievements
    }
    
    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.category == category }
        }
        return achievements
    }
    
    private var unlockedCount: Int {
        filteredAchievements.filter { achievementManager.isUnlocked($0.id) }.count
    }
    
    private var totalCount: Int {
        filteredAchievements.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Category filter
                categoryFilter
                
                // Achievement grid
                achievementGrid
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Progress indicator
            VStack(spacing: 8) {
                Text("\(unlockedCount) / \(totalCount)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Achievements Unlocked")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DesignSystem.Colors.secondaryBackground)
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * CGFloat(unlockedCount) / CGFloat(totalCount),
                                height: 8
                            )
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.lg)
        }
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: {
                    selectedCategory = nil
                }) {
                    LearningFilterChip(
                        title: "All",
                        icon: "star.fill",
                        isActive: selectedCategory == nil
                    )
                }
                
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        LearningFilterChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isActive: selectedCategory == category
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Achievement Grid
    private var achievementGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    @StateObject private var achievementManager = AchievementManager.shared
    
    private var isUnlocked: Bool {
        achievementManager.isUnlocked(achievement.id)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                        LinearGradient(
                            colors: [achievement.color.color, achievement.color.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [DesignSystem.Colors.textSecondary.opacity(0.3), DesignSystem.Colors.textSecondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(isUnlocked ? .white : DesignSystem.Colors.textSecondary)
            }
            
            // Title
            Text(achievement.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isUnlocked ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Description
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Badge
            if isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Unlocked")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(achievement.color.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(achievement.color.color.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("Locked")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(
                    isUnlocked ? achievement.color.color.opacity(0.3) : DesignSystem.Colors.border,
                    lineWidth: isUnlocked ? 2 : 1
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Achievement Category Extension
extension AchievementCategory: CaseIterable {
    static var allCases: [AchievementCategory] {
        [.quiz, .learning, .explorer, .speed, .perfectionist, .dedication]
    }
}

// MARK: - Achievement Celebration View
struct AchievementCelebrationView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Celebration animation
                ForEach(achievements) { achievement in
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [achievement.color.color, achievement.color.color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(scale)
                            
                            Image(systemName: achievement.icon)
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(scale)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Achievement Unlocked!")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(achievement.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(achievement.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Awesome!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
            .padding(32)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.xl)
            .padding(32)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            DesignSystem.Haptics.notify(.success)
        }
    }
}

