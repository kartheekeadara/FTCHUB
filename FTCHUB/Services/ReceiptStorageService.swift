//
//  ReceiptStorageService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Supabase
import UIKit
import Combine

@MainActor
class ReceiptStorageService: ObservableObject {
    static let shared = ReceiptStorageService()
    
    private let supabase = SupabaseService.shared.client
    private let bucketName = "receipts"
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    
    private init() {
        // Ensure bucket exists (this should be set up in Supabase dashboard)
        Task {
            await ensureBucketExists()
        }
    }
    
    // MARK: - Bucket Management
    
    private func ensureBucketExists() async {
        do {
            let buckets = try await supabase.storage.listBuckets()
            let bucketExists = buckets.contains { $0.name == bucketName }
            
            if !bucketExists {
                // Note: Bucket creation requires admin access
                // This should be done in Supabase dashboard or via migrations
                DebugLog.log("Warning: Receipts bucket does not exist. Please create it in Supabase dashboard.")
            }
        } catch {
            DebugLog.log("Error checking buckets: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Upload Receipt
    
    /// Upload a receipt image for an order
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - orderId: The UUID of the order
    ///   - teamId: The UUID of the team
    /// - Returns: The public URL of the uploaded receipt
    func uploadReceipt(image: UIImage, orderId: UUID, teamId: UUID) async throws -> String {
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }
        
        // Security: Verify user belongs to the team
        guard let userId = supabase.auth.currentUser?.id else {
            throw ReceiptError.notAuthenticated
        }
        
        // Security: Verify team membership
        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        // Check if user has a team_id
        guard let userTeamId = profile.teamId else {
            errorMessage = "You must be part of a team to upload receipts. Please join or create a team first."
            throw ReceiptError.unauthorized
        }
        
        guard SecurityUtils.verifyTeamMembership(userTeamId: userTeamId, requestedTeamId: teamId) else {
            errorMessage = "You don't have permission to upload receipts for this team."
            throw ReceiptError.unauthorized
        }
        
        // Security: Validate UUIDs
        guard SecurityUtils.validateUUID(orderId.uuidString) && SecurityUtils.validateUUID(teamId.uuidString) else {
            throw ReceiptError.invalidParameters
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ReceiptError.imageConversionFailed
        }
        
        // Security: Validate file size (max 10MB)
        guard SecurityUtils.validateFileSize(imageData, maxSize: 10 * 1024 * 1024) else {
            throw ReceiptError.fileTooLarge
        }
        
        // Security: Validate image type
        guard SecurityUtils.validateImageType(imageData) else {
            throw ReceiptError.invalidImageType
        }
        
        // Security: Sanitize file name to prevent path traversal
        let sanitizedOrderId = orderId.uuidString
        let sanitizedTeamId = teamId.uuidString
        let fileName = "\(sanitizedTeamId)/\(sanitizedOrderId)/\(UUID().uuidString).jpg"
        
        // Note: We skip bucket existence check because:
        // 1. Users may not have permission to list buckets
        // 2. The upload will fail with a clear error if bucket doesn't exist
        // 3. This avoids false negatives when bucket exists but listing fails
        
        do {
            // Upload to Supabase Storage
            let options = FileOptions(contentType: "image/jpeg", upsert: false)
            _ = try await supabase.storage
                .from(bucketName)
                .upload(fileName, data: imageData, options: options)
            
            // Get public URL
            let url = try supabase.storage
                .from(bucketName)
                .getPublicURL(path: fileName)
            
            // Security: Verify URL is HTTPS
            guard SecurityUtils.validateHTTPSURL(url.absoluteString) else {
                throw ReceiptError.invalidURL
            }
            
            return url.absoluteString
        } catch {
            let errorMsg = error.localizedDescription
            let errorString = errorMsg.lowercased()
            TelemetryService.shared.logError(error, context: ["action": "upload_receipt"])
            
            // Provide more specific error messages
            if error is ReceiptError {
                // Already a ReceiptError, re-throw it
                if let receiptError = error as? ReceiptError {
                    errorMessage = receiptError.errorDescription ?? errorMsg
                    throw receiptError
                }
            }
            
            if errorString.contains("bucket") || errorString.contains("not found") || errorString.contains("does not exist") {
                let detailedError = "Receipt storage bucket '\(bucketName)' is not configured. Please create it in Supabase Dashboard > Storage. Name: 'receipts', Type: Private."
                errorMessage = detailedError
                DebugLog.log("❌ \(detailedError)")
                throw ReceiptError.bucketNotFound
            } else if errorString.contains("permission") || errorString.contains("unauthorized") || errorString.contains("policy") || errorString.contains("row-level security") {
                // Provide more helpful error message
                if errorString.contains("row-level security") {
                    errorMessage = "Receipt upload failed: Database security policy error. Please ensure you are part of a team and that storage policies are configured correctly. If the problem persists, contact your administrator."
                } else {
                    errorMessage = "You don't have permission to upload receipts. Please ensure you are part of a team and that storage policies are configured correctly."
                }
                DebugLog.log("❌ Permission error: \(errorMsg)")
                throw ReceiptError.unauthorized
            } else if errorString.contains("file too large") || errorString.contains("size") {
                errorMessage = "Receipt image is too large. Maximum size is 10MB. Please compress the image and try again."
                throw ReceiptError.fileTooLarge
            } else {
                errorMessage = "Failed to upload receipt: \(errorMsg)"
                throw ReceiptError.uploadFailed(errorMsg)
            }
        }
    }
    
    /// Upload multiple receipt images
    func uploadReceipts(images: [UIImage], orderId: UUID, teamId: UUID) async throws -> [String] {
        var urls: [String] = []
        
        for (index, image) in images.enumerated() {
            do {
                let url = try await uploadReceipt(image: image, orderId: orderId, teamId: teamId)
                urls.append(url)
                uploadProgress = Double(index + 1) / Double(images.count)
            } catch {
                // Continue with other images even if one fails
                DebugLog.log("Failed to upload receipt \(index + 1): \(error.localizedDescription)")
            }
        }
        
        uploadProgress = 0
        return urls
    }
    
    // MARK: - Download Receipt
    
    /// Download a receipt image from URL
    func downloadReceipt(url: String) async throws -> UIImage? {
        guard let imageURL = URL(string: url) else {
            throw ReceiptError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            return UIImage(data: data)
        } catch {
            throw ReceiptError.downloadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Receipt
    
    /// Delete a receipt from storage
    func deleteReceipt(url: String, orderId: UUID, teamId: UUID) async throws {
        // Extract file path from URL
        guard let urlComponents = URL(string: url)?.pathComponents,
              let bucketIndex = urlComponents.firstIndex(of: bucketName),
              bucketIndex < urlComponents.count - 1 else {
            throw ReceiptError.invalidURL
        }
        
        let fileName = urlComponents[(bucketIndex + 1)...].joined(separator: "/")
        
        do {
            try await supabase.storage
                .from(bucketName)
                .remove(paths: [fileName])
        } catch {
            throw ReceiptError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Image Compression
    
    /// Compress and resize image for optimal storage
    func compressImage(_ image: UIImage, maxWidth: CGFloat = 1920, maxHeight: CGFloat = 1920, quality: CGFloat = 0.8) -> UIImage? {
        let size = image.size
        
        // Calculate scaling factor
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let scaleFactor = min(widthRatio, heightRatio, 1.0)
        
        // Skip compression if image is already small enough
        guard scaleFactor < 1.0 || quality < 1.0 else {
            return image
        }
        
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image
        }
        
        return resizedImage
    }
}

// MARK: - Receipt Errors

enum ReceiptError: LocalizedError, Equatable {
    case imageConversionFailed
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)
    case invalidURL
    case bucketNotFound
    case notAuthenticated
    case unauthorized
    case invalidParameters
    case fileTooLarge
    case invalidImageType
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG format"
        case .uploadFailed(let message):
            return "Failed to upload receipt: \(message)"
        case .downloadFailed(let message):
            return "Failed to download receipt: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete receipt: \(message)"
        case .invalidURL:
            return "Invalid receipt URL"
        case .bucketNotFound:
            return "Receipts storage bucket not found"
        case .notAuthenticated:
            return "You must be signed in to upload receipts"
        case .unauthorized:
            return "You don't have permission to upload receipts for this team"
        case .invalidParameters:
            return "Invalid order or team ID"
        case .fileTooLarge:
            return "Image file is too large. Maximum size is 10MB"
        case .invalidImageType:
            return "Invalid image format. Please use JPEG, PNG, or GIF"
        }
    }
}

