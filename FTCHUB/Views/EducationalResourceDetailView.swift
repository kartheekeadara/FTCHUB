//
//  EducationalResourceDetailView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

struct EducationalResourceDetailView: View {
    let resource: FTCResource
    @State private var selectedSection: ResourceSection = .subpages
    @State private var showingFlashcards = false
    @State private var isBookmarked = false
    @State private var isDownloaded = false
    @State private var isDownloading = false
    @State private var downloadError: String?
    @State private var showingDownloadError = false
    @StateObject private var resourcesService = ResourcesService.shared
    @StateObject private var flashcardManager = FlashcardManager.shared
    @StateObject private var downloadManager = ResourceDownloadManager.shared
    
    enum ResourceSection: String, CaseIterable {
        case subpages = "Topics"
    }
    
    private var relatedFlashcardDecks: [FlashcardDeck] {
        flashcardManager.decks.filter { $0.category == resource.category }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Content Section
                contentSection
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(resource.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .id("\(resource.id)-\(selectedSection)")
        .onAppear {
            // Track resource view (completely non-blocking, runs in background after view appears)
            // Don't await - let view render immediately
            Task.detached(priority: .background) {
                await resourcesService.incrementViewCount(resource)
                try? await resourcesService.markAsRead(resource)
            }
            
            // Update bookmark and download state
            isBookmarked = resourcesService.isBookmarked(resource)
            isDownloaded = downloadManager.isDownloaded(resourceId: resource.id)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // Bookmark button
                    Button(action: {
                        Task {
                            DesignSystem.Haptics.selection()
                            do {
                                if isBookmarked {
                                    try await resourcesService.removeBookmark(resource)
                                } else {
                                    try await resourcesService.addBookmark(resource)
                                }
                                isBookmarked = resourcesService.isBookmarked(resource)
                            } catch {
                                DesignSystem.Haptics.notify(.error)
                            }
                        }
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? categoryColor : DesignSystem.Colors.textSecondary)
                    }
                    
                    // Download button (if PDF)
                    if resource.url.hasSuffix(".pdf") || resource.url.contains(".pdf") {
                        Button(action: {
                            handleDownload()
                        }) {
                            if isDownloading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                                    .foregroundColor(isDownloaded ? .green : DesignSystem.Colors.textSecondary)
                            }
                        }
                        .disabled(isDownloading)
                    }
                }
            }
        }
        .alert("Download Error", isPresented: $showingDownloadError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(downloadError ?? "Failed to download resource")
        }
        .sheet(isPresented: $showingFlashcards) {
            if !relatedFlashcardDecks.isEmpty {
                NavigationStack {
                    FlashcardDeckSelectionView(decks: relatedFlashcardDecks)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon and Title
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: resource.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(resource.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(resource.description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Action Buttons
            HStack(spacing: 12) {
                Spacer()
                
                // Study Flashcards button (if decks available)
                if !relatedFlashcardDecks.isEmpty {
                    Button(action: {
                        DesignSystem.Haptics.selection()
                        showingFlashcards = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Study (\(relatedFlashcardDecks.reduce(0) { $0 + $1.flashcards.count }))")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                
                // Download button (if PDF and not already downloaded)
                if (resource.url.hasSuffix(".pdf") || resource.url.contains(".pdf")) && !isDownloaded {
                    Button(action: {
                        handleDownload()
                    }) {
                        HStack(spacing: 8) {
                            if isDownloading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(isDownloading ? "Downloading..." : "Download")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isDownloading)
                }
                
                // Open Website button
                Button(action: {
                    openResourceURL()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Open Website")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [categoryColor, categoryColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: categoryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [
                    categoryColor.opacity(0.05),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        Group {
            switch selectedSection {
            case .subpages:
                subpagesContent
                    .id("subpages-\(resource.id)")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedSection)
    }
    
    // MARK: - Subpages Content
    private var subpagesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let subPages = resource.subPages, !subPages.isEmpty {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title3)
                        .foregroundColor(categoryColor)
                    Text("Explore Topics")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding(.horizontal)
                
                // Topic Cards - Use regular VStack instead of LazyVStack for immediate rendering
                VStack(spacing: 16) {
                    ForEach(Array(subPages.enumerated()), id: \.element.id) { index, subPage in
                        SubPageCard(
                            subPage: subPage,
                            categoryColor: categoryColor,
                            index: index
                        ) {
                            // Open directly in Safari instead of showing subpage browser
                            DesignSystem.Haptics.selection()
                            openSubPageURL(subPage.url)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                EnhancedEmptyStateView(
                    icon: "book.closed",
                    title: "No Topics Available",
                    message: "This resource doesn't have any sub-topics yet. Tap 'Open Website' to view the full resource.",
                    actionTitle: nil,
                    action: nil
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 20)
    }
    
    // MARK: - Category Color
    private var categoryColor: Color {
        switch resource.category {
        case .official: return .blue
        case .rules: return .purple
        case .community: return .green
        case .technical: return .orange
        case .programming: return .indigo
        case .strategy: return .pink
        case .safety: return .red
        case .awards: return .yellow
        case .video: return .red
        case .parts: return .gray
        }
    }
    
    // MARK: - Helper Functions
    
    private func openResourceURL() {
        guard let url = URL(string: resource.url), url.scheme != nil else {
            DesignSystem.Haptics.notify(.error)
            downloadError = "Invalid URL"
            showingDownloadError = true
            return
        }
        
        DesignSystem.Haptics.selection()
        UIApplication.shared.open(url) { success in
            if !success {
                DesignSystem.Haptics.notify(.error)
                downloadError = "Failed to open URL"
                showingDownloadError = true
            }
        }
    }
    
    private func openSubPageURL(_ urlString: String) {
        guard let url = URL(string: urlString), url.scheme != nil else {
            DesignSystem.Haptics.notify(.error)
            downloadError = "Invalid URL"
            showingDownloadError = true
            return
        }
        
        DesignSystem.Haptics.selection()
        UIApplication.shared.open(url) { success in
            if !success {
                DesignSystem.Haptics.notify(.error)
                downloadError = "Failed to open URL"
                showingDownloadError = true
            }
        }
    }
    
    private func handleDownload() {
        guard let url = URL(string: resource.url), url.scheme != nil else {
            DesignSystem.Haptics.notify(.error)
            downloadError = "Invalid URL"
            showingDownloadError = true
            return
        }
        
        isDownloading = true
        downloadError = nil
        
        Task {
            do {
                try await downloadManager.downloadResource(resource, url: url)
                await MainActor.run {
                    isDownloaded = true
                    isDownloading = false
                    DesignSystem.Haptics.notify(.success)
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    downloadError = error.localizedDescription
                    showingDownloadError = true
                    DesignSystem.Haptics.notify(.error)
                }
            }
        }
    }
}

// MARK: - SubPage Card
struct SubPageCard: View {
    let subPage: ResourceSubPage
    let categoryColor: Color
    let index: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(subPage.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subPage.description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                
                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: categoryColor.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(categoryColor.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SubPage Browser View
#if canImport(SafariServices)
struct SubPageBrowserView: View {
    let subPage: ResourceSubPage
    @Environment(\.dismiss) private var dismiss
    
    private var safeURL: URL? {
        guard let url = URL(string: subPage.url), url.scheme != nil else {
            return nil
        }
        return url
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let url = safeURL {
                    SafariView(url: url)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Invalid URL")
                            .font(.headline)
                        Text("This resource link is not valid.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle(subPage.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif
