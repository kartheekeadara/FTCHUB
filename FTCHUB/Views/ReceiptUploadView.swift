//
//  ReceiptUploadView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct ReceiptUploadView: View {
    @EnvironmentObject var receiptStorage: ReceiptStorageService
    @State private var uploadedUrls: [String] = []
    @State private var errorMessage: String?
    
    let orderId: UUID
    let teamId: UUID
    var onUploadComplete: ([String]) -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Current Receipts
            if !uploadedUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(Array(uploadedUrls.enumerated()), id: \.offset) { index, url in
                            ReceiptThumbnailView(url: url, onDelete: {
                                uploadedUrls.remove(at: index)
                            })
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            
            // Receipt upload functionality removed - camera and photo library permissions no longer available
            Text("Receipt upload is currently unavailable. You can still create orders without receipt attachments.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
            
            // Upload Progress
            if receiptStorage.isUploading {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ProgressView(value: receiptStorage.uploadProgress, total: 1.0)
                        .progressViewStyle(.linear)
                    Text("Uploading receipt...")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            
            // Error Message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.error)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }
}

// MARK: - Receipt Thumbnail View

struct ReceiptThumbnailView: View {
    let url: String
    let onDelete: (() -> Void)?
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var showingFullImage = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            Button(action: { showingFullImage = true }) {
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .frame(width: 100, height: 100)
                .cornerRadius(DesignSystem.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
            }
            
            // Delete Button
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .task {
            await loadImage()
        }
        .sheet(isPresented: $showingFullImage) {
            if let image = image {
                ReceiptFullImageView(image: image)
            }
        }
    }
    
    private func loadImage() async {
        do {
            let receiptStorage = ReceiptStorageService.shared
            let loadedImage = try await receiptStorage.downloadReceipt(url: url)
            image = loadedImage
            isLoading = false
        } catch {
            isLoading = false
            DebugLog.log("Failed to load receipt: \(error.localizedDescription)")
        }
    }
}

// MARK: - Receipt Full Image View

struct ReceiptFullImageView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Camera View (Removed - camera permission no longer available)

#Preview {
    ReceiptUploadView(
        orderId: UUID(),
        teamId: UUID(),
        onUploadComplete: { _ in }
    )
    .environmentObject(ReceiptStorageService.shared)
}

