//
//  TroubleshootingView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct TroubleshootingView: View {
    @StateObject private var service = TroubleshootingService.shared
    @State private var searchText = ""
    @State private var selectedGuide: TroubleshootingGuide? = nil
    
    var filteredGuides: [TroubleshootingGuide] {
        if searchText.isEmpty {
            return service.guides
        }
        return service.guides.filter { guide in
            guide.title.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredGuides) { guide in
                    Button(action: {
                        selectedGuide = guide
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(guide.title)
                                    .font(.headline)
                                Spacer()
                                Text(guide.difficulty.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(guide.difficulty.color.opacity(0.2))
                                    .foregroundColor(guide.difficulty.color)
                                    .cornerRadius(8)
                            }
                            
                            Text(guide.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(guide.solutions.count) steps • \(guide.timeEstimate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search problems...")
            .navigationTitle("Troubleshooting")
            .sheet(item: $selectedGuide) { guide in
                GuideDetailView(guide: guide)
            }
        }
    }
}

struct GuideDetailView: View {
    let guide: TroubleshootingGuide
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(guide.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(guide.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !guide.symptoms.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Symptoms")
                                .font(.headline)
                            ForEach(guide.symptoms, id: \.self) { symptom in
                                HStack(alignment: .top) {
                                    Text("•")
                                    Text(symptom)
                                }
                                .font(.body)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Solutions")
                            .font(.headline)
                        ForEach(guide.solutions, id: \.step) { solution in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Step \(solution.step): \(solution.action)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(solution.details)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    if !guide.prevention.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prevention")
                                .font(.headline)
                            ForEach(guide.prevention, id: \.self) { tip in
                                HStack(alignment: .top) {
                                    Text("✓")
                                    Text(tip)
                                }
                                .font(.body)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TroubleshootingView()
}

