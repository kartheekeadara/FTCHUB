//
//  RulesReferenceView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

struct RulesReferenceView: View {
    @State private var searchText = ""
    @State private var selectedCategory = RuleCategory.all
    
    enum RuleCategory: String, CaseIterable {
        case all = "All"
        case game = "Game Play"
        case robot = "Robot"
        case safety = "Safety"
        case scoring = "Scoring"
        case autonomous = "Autonomous"
        case teleop = "Teleop"
        case endgame = "Endgame"
        case ranking = "Ranking Pts"
        case penalties = "Penalties"
        
        var icon: String {
            switch self {
            case .all: return "book.fill"
            case .game: return "gamecontroller.fill"
            case .robot: return "gearshape.fill"
            case .safety: return "shield.checkered"
            case .scoring: return "target"
            case .autonomous: return "brain.head.profile"
            case .teleop: return "gamecontroller"
            case .endgame: return "flag.checkered"
            case .ranking: return "chart.bar.fill"
            case .penalties: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    private var filteredRules: [Rule] {
        var rules = decodeRules
        
        if selectedCategory != .all {
            rules = rules.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            rules = rules.filter { rule in
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return true }
                return rule.title.localizedCaseInsensitiveContains(query) ||
                rule.content.localizedCaseInsensitiveContains(query) ||
                rule.ruleNumber.localizedCaseInsensitiveContains(query) ||
                rule.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            }
        }
        
        return rules
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.top, DesignSystem.Spacing.md)

            // Category chips: height follows chip row only (ZStack was stretching vertically and pushing the list down).
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(RuleCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                            #if canImport(UIKit)
                            DesignSystem.Haptics.selection()
                            #endif
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .overlay(alignment: .trailing) {
                LinearGradient(
                    colors: [Color.clear, DesignSystem.Colors.background],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 40)
                .allowsHitTesting(false)
            }

            if filteredRules.isEmpty {
                EmptyResultsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(filteredRules) { rule in
                            RuleCard(rule: rule)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabBarScrollInset()
                .background(DesignSystem.Colors.background)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Rules Reference")
        .navigationBarTitleDisplayMode(.inline)
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }
}

// MARK: - Models

struct Rule: Identifiable, Hashable {
    let id = UUID()
    let ruleNumber: String
    let title: String
    let content: String
    let category: RulesReferenceView.RuleCategory
    let tags: [String]
    let source: URL?
}

private let decodeRules: [Rule] = [
    Rule(
        ruleNumber: "G101",
        title: "Gracious Professionalism®",
        content: "Teams must exhibit safe, respectful behavior toward all participants, volunteers, and equipment. Repeated or egregious violations escalate from warnings to yellow/red cards.",
        category: .game,
        tags: ["safety", "conduct", "cards"],
        source: URL(string: "https://ftc-resources.firstinspires.org/ftc/game/manual")
    ),
    Rule(
        ruleNumber: "R302",
        title: "Starting Box Constraints",
        content: "Robots must fit completely within an 18” x 18” x 18” volume at inspection and before match start. Extending once the match begins is permitted.",
        category: .robot,
        tags: ["inspection", "dimension", "setup"],
        source: URL(string: "https://ftc-resources.firstinspires.org/ftc/game/manual")
    ),
    Rule(
        ruleNumber: "S102",
        title: "Electrical Safety",
        content: "Main power switches must be easily accessible and clearly labeled. Loose wires, exposed battery terminals, or unsafe charging practices can result in disablement.",
        category: .safety,
        tags: ["power", "inspection", "disable"],
        source: URL(string: "https://ftc-resources.firstinspires.org/ftc/game/manual")
    ),
    Rule(
        ruleNumber: "DE-SC1",
        title: "Autonomous Artifact Values",
        content: "During autonomous, classified artifacts score 3 points each and overflow artifacts score 1 point when fully supported by a valid gate square or overflow bin.",
        category: .autonomous,
        tags: ["artifacts", "gates", "autonomous scoring"],
        source: URL(string: "https://ftc-scoring.firstinspires.org/scoreCalculator")
    ),
    Rule(
        ruleNumber: "DE-SC2",
        title: "Autonomous Pattern Bonus",
        content: "Each correctly patterned gate that matches the published randomization motif adds 2 points. The pattern repeats every three gates in numerical order.",
        category: .autonomous,
        tags: ["randomization", "pattern", "bonus"],
        source: URL(string: "https://ftc-scoring.firstinspires.org/scoreCalculator")
    ),
    Rule(
        ruleNumber: "DE-SC3",
        title: "Teleop Artifact Scoring",
        content: "Classified artifacts placed during teleop are worth 3 points; overflow artifacts are worth 1 point. Artifacts delivered through the depot each count for 1 additional point.",
        category: .teleop,
        tags: ["teleop", "artifacts", "depot"],
        source: URL(string: "https://ftc-scoring.firstinspires.org/scoreCalculator")
    ),
    Rule(
        ruleNumber: "DE-SC4",
        title: "Gate Pattern Matching",
        content: "Teleop gate squares that match the randomization motif earn 2 points each. Only the color occupying the square when time expires counts.",
        category: .teleop,
        tags: ["pattern", "motif", "teleop"],
        source: URL(string: "https://ftc-scoring.firstinspires.org/scoreCalculator")
    ),
    Rule(
        ruleNumber: "DE-SC5",
        title: "Endgame Base Bonuses",
        content: "Robots ending fully within their alliance base earn 10 points each; partial contact scores 5 points. Both robots fully docked grant an additional 10 point alliance bonus.",
        category: .endgame,
        tags: ["endgame", "base", "docking"],
        source: URL(string: "https://ftc-scoring.firstinspires.org/scoreCalculator")
    ),
    Rule(
        ruleNumber: "RP-MOVE",
        title: "Movement Ranking Point",
        content: "Earned when an alliance accumulates at least 16 combined auto leave and teleop base points. Tracking this threshold during the match helps strategic decision-making.",
        category: .ranking,
        tags: ["ranking point", "threshold", "strategy"],
        source: URL(string: "https://ftc-scoring.firstinspires.org/scoreCalculator")
    ),
    Rule(
        ruleNumber: "RP-GOAL",
        title: "Goal Ranking Point",
        content: "Awarded if the alliance secures a total of 36 artifacts (autonomous and teleop combined) in valid scoring locations.",
        category: .ranking,
        tags: ["artifacts", "ranking point", "telemetry"],
        source: URL(string: "https://ftc-scoring.firstinspires.org/scoreCalculator")
    ),
    Rule(
        ruleNumber: "RP-PATTERN",
        title: "Pattern Ranking Point",
        content: "Granted when the alliance scores at least 18 pattern points across autonomous and teleop phases—equivalent to nine successful motif matches.",
        category: .ranking,
        tags: ["pattern", "motif", "ranking point"],
        source: URL(string: "https://ftc-scoring.firstinspires.org/scoreCalculator")
    ),
    Rule(
        ruleNumber: "G207",
        title: "Pinning & Trapping",
        content: "Robots may not trap or pin opponents for more than 5 seconds and must move 3 feet away before re-engaging. Violations: major penalty per occurrence.",
        category: .penalties,
        tags: ["defense", "pinning", "penalty"],
        source: URL(string: "https://ftc-resources.firstinspires.org/ftc/game/manual")
    ),
    Rule(
        ruleNumber: "G210",
        title: "Human Player Interaction",
        content: "Human players may only enter the field to interact with overflow bins when prompted by referees and must immediately exit once complete.",
        category: .game,
        tags: ["human player", "overflow", "field access"],
        source: URL(string: "https://ftc-resources.firstinspires.org/ftc/game/manual")
    ),
    Rule(
        ruleNumber: "R407",
        title: "Allowed Artifact Manipulators",
        content: "Robot mechanisms may not intentionally damage, launch, or entangle artifacts. Mechanisms that trap an artifact must release it before match end.",
        category: .robot,
        tags: ["mechanisms", "artifacts", "entanglement"],
        source: URL(string: "https://ftc-resources.firstinspires.org/ftc/game/manual")
    ),
    Rule(
        ruleNumber: "DE-FIELD1",
        title: "Gate Randomization Motifs",
        content: "Prior to each match, referees randomize gate motifs (1–3). Drive teams must confirm the displayed arrangement before the autonomous countdown begins.",
        category: .autonomous,
        tags: ["field", "setup", "randomization"],
        source: URL(string: "https://www.firstinspires.org/programs/ftc/game-and-season")
    ),
    Rule(
        ruleNumber: "DE-STRAT1",
        title: "Overflow Collaboration",
        content: "Alliances may strategically queue overflow artifacts by communicating depot cadence, enabling smoother teleop cycles and shared scoring responsibilities.",
        category: .teleop,
        tags: ["strategy", "overflow", "communication"],
        source: URL(string: "https://www.firstinspires.org/programs/ftc/game-and-season")
    )
]

// MARK: - Components

private struct RuleCard: View {
    let rule: Rule
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Rule number badge: min 52pt wide × 24pt tall
                Text(rule.ruleNumber)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 52, minHeight: 24)
                    .padding(.horizontal, 8)
                    .background(DesignSystem.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(rule.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer(minLength: 0)
            }
            
            Text(rule.content)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if !rule.tags.isEmpty {
                TagCloud(tags: rule.tags)
            }
            
            if let source = rule.source {
                Button {
                    openURL(source)
                } label: {
                    Label("View source guidance", systemImage: "link")
                        .font(.footnote.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(minHeight: 44) // Adequate tap target
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.14), radius: 10, x: 0, y: 4)
        .contextMenu {
            Button {
                #if canImport(UIKit)
                UIPasteboard.general.string = "\(rule.ruleNumber): \(rule.title)\n\(rule.content)"
                #endif
            } label: {
                Label("Copy summary", systemImage: "doc.on.doc")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to open the official source link.")
    }
}

private struct TagCloud: View {
    let tags: [String]
    
    var body: some View {
        // Flow layout using wrapping HStack simulation
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.separator.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            Spacer(minLength: 0)
        }
    }
}

private struct CategoryChip: View {
    let category: RulesReferenceView.RuleCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryBackground)
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? DesignSystem.Colors.shadow.opacity(0.25) : .clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField("Search by rule, keyword, or tag", text: $text)
                .textFieldStyle(.plain)
                .submitLabel(.search)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

private struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()
            
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Gradients.primary)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.3), radius: 12, x: 0, y: 6)
            
            Text("No Matches Yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Try a different keyword, switch categories, or clear your filters to browse all DECODE rules.")
                .font(.footnote)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    RulesReferenceView()
}