//
//  ScheduleScannerView.swift
//  FTCHUB
//
//  Created for Schedule Scanning Feature - Phase 1
//  Camera interface for scanning match schedules
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

struct ScheduleScannerView: View {
    @EnvironmentObject var scanService: ScheduleScanService
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var teamService: TeamService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var pickerRequest: PickerRequest?
    @State private var scanResult: ScheduleScanResult?
    @State private var extractedMatches: [ExtractedMatchData] = []
    @State private var showingPreview = false
    @State private var errorMessage: String?
    @State private var isProcessing = false
    @State private var didAutoProcessSelectedImage = false
    
    private struct PickerRequest: Identifiable {
        let id = UUID()
        let sourceType: UIImagePickerController.SourceType
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    if isProcessing || scanService.isProcessing {
                        processingView
                    } else if let image = selectedImage, scanResult == nil {
                        imagePreviewView(image: image)
                    } else if scanResult == nil {
                        emptyStateView
                    }
                    // Note: When scanResult is set, we automatically show preview (no results page)
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Scan Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $pickerRequest) { request in
                ImagePicker(
                    sourceType: request.sourceType,
                    selectedImage: $selectedImage
                )
            }
            .onChange(of: selectedImage) { _, newValue in
                // Make "scan from photo" reliable: when the picker returns an image,
                // immediately proceed to scanning once per selection.
                guard let image = newValue else {
                    didAutoProcessSelectedImage = false
                    return
                }
                guard !didAutoProcessSelectedImage else { return }
                didAutoProcessSelectedImage = true
                processImage(image)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let result = scanResult {
                    ScheduleScanPreviewView(
                        scanResult: result,
                        extractedMatches: extractedMatches,
                        shouldDismissScanner: Binding(
                            get: { false },
                            set: { if $0 { dismiss() } }
                        )
                    )
                    .environmentObject(scanService)
                    .environmentObject(scheduleService)
                    .environmentObject(teamService)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Scan Match Schedule")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Take a photo of your match schedule or select one from your photo library")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Button(action: {
                    Task {
                        // Check if camera is available on device
                        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                            await MainActor.run {
                                errorMessage = "Camera is not available on this device."
                            }
                            return
                        }
                        
                        let granted = await requestCameraPermission()
                        await MainActor.run {
                            if granted {
                                pickerRequest = PickerRequest(sourceType: .camera)
                            } else {
                                errorMessage = "Camera permission is required to scan schedules. Please enable camera access in Settings."
                            }
                        }
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                        Text("Take Photo")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Gradients.primary)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                }
                
                Button(action: {
                    Task {
                        let granted = await requestPhotoLibraryPermission()
                        await MainActor.run {
                            if granted {
                                pickerRequest = PickerRequest(sourceType: .photoLibrary)
                            } else {
                                errorMessage = "Photo Library permission is required to select a schedule image. Please enable Photos access in Settings."
                            }
                        }
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                        Text("Choose from Library")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    // MARK: - Image Preview
    
    private func imagePreviewView(image: UIImage) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.3), radius: 8, x: 0, y: 4)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: {
                    selectedImage = nil
                    scanResult = nil
                }) {
                    Text("Retake")
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
                
                Button(action: {
                    processImage(image)
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Scan")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Gradients.primary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .disabled(isProcessing)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ProgressView(value: scanService.processingProgress)
                .progressViewStyle(.linear)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Processing Image...")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Extracting text from schedule")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
    
    // MARK: - Result View
    
    private func resultView(result: ScheduleScanResult) -> some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Summary Card
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Scan Results")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("\(result.textBlocks.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text("Text Blocks")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                            Text("\(Int(result.overallConfidence * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(confidenceColor(result.overallConfidence))
                            Text("Confidence")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Processing Time:")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("\(result.processingTimeMs)ms")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                
                // Extracted Text Preview
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Extracted Text")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    let fullText = scanService.extractFullText(from: result)
                    Text(fullText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding(DesignSystem.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .textSelection(.enabled)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                
                // Action Buttons
                Button(action: {
                    extractedMatches = scanService.parseSchedule(from: result)
                    showingPreview = true
                }) {
                    Text("Continue to Preview")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Gradients.primary)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Button(action: {
                    selectedImage = nil
                    scanResult = nil
                }) {
                    Text("Scan Again")
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil
        scanResult = nil
        
        Task {
            do {
                // Basic sanity check (helps catch "blank"/invalid images from picker edge cases)
                guard image.size.width > 10, image.size.height > 10 else {
                    throw ScheduleScanError.invalidImage
                }
                
                // Monitor progress from service
                let progressTask = Task {
                    while scanService.isProcessing {
                        await MainActor.run {
                            isProcessing = scanService.isProcessing
                        }
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                }
                
                let result = try await scanService.processImage(image)
                
                progressTask.cancel()
                
                await MainActor.run {
                    // Immediately parse and show preview, skipping results page
                    extractedMatches = scanService.parseSchedule(from: result)
                    scanResult = result
                    isProcessing = false
                    // Always show preview, even if no matches found (user can see what was extracted)
                    showingPreview = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 {
            return DesignSystem.Colors.success
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return DesignSystem.Colors.error
        }
    }
    
    private func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    private func requestPhotoLibraryPermission() async -> Bool {
        // Use legacy read authorization (pick images only; no write/add access needed).
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization { continuation.resume(returning: $0) }
            }
            return newStatus == .authorized || newStatus == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Check if source type is available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            // If camera is not available, fall back to photo library
            if sourceType == .camera {
                picker.sourceType = .photoLibrary
            } else {
                picker.sourceType = sourceType
            }
        }
        
        picker.delegate = context.coordinator
        // Enables built-in crop UI (and rotation) for both camera + library
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No-op. This view is presented via `.sheet(item:)` so each request gets its own picker.
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            DispatchQueue.main.async {
                if let edited = info[.editedImage] as? UIImage {
                    self.parent.selectedImage = edited
                } else if let original = info[.originalImage] as? UIImage {
                    self.parent.selectedImage = original
                }
                picker.dismiss(animated: true, completion: nil)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
