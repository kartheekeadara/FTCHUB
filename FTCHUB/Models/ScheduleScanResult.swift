//
//  ScheduleScanResult.swift
//  FTCHUB
//
//  Created for Schedule Scanning Feature - Phase 1
//

import Foundation
import CoreGraphics

// MARK: - Scan Result Models

/// Represents the result of an OCR scan operation
struct ScheduleScanResult {
    /// Raw text blocks extracted from the image
    let textBlocks: [TextBlock]
    
    /// Confidence score for the overall scan (0.0 - 1.0)
    let overallConfidence: Double
    
    /// Processing time in milliseconds
    let processingTimeMs: Int
    
    /// Original image dimensions
    let imageSize: CGSize
    
    /// Whether the scan was successful
    var isSuccessful: Bool {
        !textBlocks.isEmpty && overallConfidence > 0.3
    }
}

/// Represents a single block of text extracted from the image
struct TextBlock: Identifiable {
    let id: UUID
    let text: String
    let boundingBox: CGRect
    let confidence: Double
    
    init(id: UUID = UUID(), text: String, boundingBox: CGRect, confidence: Double) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}

/// Represents a potential match entry extracted from scanned schedule
struct ExtractedMatchData: Identifiable {
    let id: UUID
    var matchNumber: String?
    var scheduledTime: String?
    var redTeam1: String?
    var redTeam2: String?
    var blueTeam1: String?
    var blueTeam2: String?
    
    /// Confidence score for this match extraction (0.0 - 1.0)
    var confidence: Double
    
    /// Warnings or validation issues
    var warnings: [String]
    
    init(id: UUID = UUID()) {
        self.id = id
        self.matchNumber = nil
        self.scheduledTime = nil
        self.redTeam1 = nil
        self.redTeam2 = nil
        self.blueTeam1 = nil
        self.blueTeam2 = nil
        self.confidence = 0.0
        self.warnings = []
    }
    
    /// Whether this match data is valid (has at least match number)
    var isValid: Bool {
        matchNumber != nil && !matchNumber!.isEmpty
    }
    
    /// Whether this match data is complete (has all required fields)
    var isComplete: Bool {
        isValid && scheduledTime != nil && (redTeam1 != nil || blueTeam1 != nil)
    }
}

// MARK: - Scan Errors

enum ScheduleScanError: LocalizedError {
    case cameraUnavailable
    case permissionDenied
    case imageProcessingFailed
    case noTextDetected
    case ocrFailed(underlyingError: Error)
    case invalidImage
    case processingTimeout
    
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .permissionDenied:
            return "Camera permission was denied. Please enable camera access in Settings."
        case .imageProcessingFailed:
            return "Failed to process the image. Please try again."
        case .noTextDetected:
            return "No text was detected in the image. Please ensure the schedule is clearly visible."
        case .ocrFailed(let error):
            return "OCR processing failed: \(error.localizedDescription)"
        case .invalidImage:
            return "Invalid image. Please select a different image."
        case .processingTimeout:
            return "Processing took too long. Please try with a smaller image or better lighting."
        }
    }
}
