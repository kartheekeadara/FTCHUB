//
//  ScheduleScanService.swift
//  FTCHUB
//
//  Created for Schedule Scanning Feature - Phase 1
//  Service for managing schedule scanning operations
//

import Foundation
import Combine
import UIKit

@MainActor
final class ScheduleScanService: ObservableObject {
    static let shared = ScheduleScanService()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var lastScanResult: ScheduleScanResult?
    
    private let ocrProcessor = ScheduleOCRProcessor.self
    
    private init() {}
    
    // MARK: - Image Processing
    
    /// Process an image and extract text using OCR
    /// - Parameters:
    ///   - image: The UIImage to process
    ///   - language: Optional language code for OCR (default: English)
    /// - Returns: ScheduleScanResult with extracted text blocks
    /// - Throws: ScheduleScanError if processing fails
    func processImage(_ image: UIImage, language: String = "en-US") async throws -> ScheduleScanResult {
        isProcessing = true
        processingProgress = 0.0
        errorMessage = nil
        
        defer {
            isProcessing = false
            processingProgress = 1.0
        }
        
        do {
            // Update progress
            processingProgress = 0.3
            
            // Process image with OCR
            let result = try await ocrProcessor.processImage(image, language: language)
            
            // Update progress
            processingProgress = 0.9
            
            // Store result
            lastScanResult = result
            
            processingProgress = 1.0
            
            return result
        } catch {
            errorMessage = error.localizedDescription
            if let scanError = error as? ScheduleScanError {
                throw scanError
            } else {
                throw ScheduleScanError.ocrFailed(underlyingError: error)
            }
        }
    }
    
    /// Process image from data
    /// - Parameters:
    ///   - data: Image data
    ///   - language: Optional language code for OCR
    /// - Returns: ScheduleScanResult with extracted text blocks
    /// - Throws: ScheduleScanError if processing fails
    func processImageData(_ data: Data, language: String = "en-US") async throws -> ScheduleScanResult {
        guard let image = UIImage(data: data) else {
            throw ScheduleScanError.invalidImage
        }
        
        return try await processImage(image, language: language)
    }
    
    // MARK: - Text Processing
    
    /// Get all text from scan result as a single string
    /// - Parameter result: ScheduleScanResult
    /// - Returns: Combined text from all text blocks
    func extractFullText(from result: ScheduleScanResult) -> String {
        let sortedBlocks = result.textBlocks.sorted { block1, block2 in
            // Sort by Y position (top to bottom), then X position (left to right)
            if abs(block1.boundingBox.midY - block2.boundingBox.midY) < 10 {
                return block1.boundingBox.midX < block2.boundingBox.midX
            }
            return block1.boundingBox.midY < block2.boundingBox.midY
        }
        
        return sortedBlocks.map { $0.text }.joined(separator: " ")
    }
    
    /// Get text blocks grouped into rows
    /// - Parameter result: ScheduleScanResult
    /// - Returns: Array of text block arrays, each representing a row
    func extractRows(from result: ScheduleScanResult) -> [[TextBlock]] {
        return ScheduleOCRProcessor.groupIntoRows(result.textBlocks)
    }
    
    // MARK: - Pattern Extraction
    
    /// Extract potential match numbers from scan result
    /// - Parameter result: ScheduleScanResult
    /// - Returns: Array of potential match number strings
    func extractMatchNumbers(from result: ScheduleScanResult) -> [String] {
        let fullText = extractFullText(from: result)
        return ScheduleOCRProcessor.extractMatchNumbers(from: fullText)
    }
    
    /// Extract potential team numbers from scan result
    /// - Parameter result: ScheduleScanResult
    /// - Returns: Array of potential team number strings
    func extractTeamNumbers(from result: ScheduleScanResult) -> [String] {
        let fullText = extractFullText(from: result)
        return ScheduleOCRProcessor.extractTeamNumbers(from: fullText)
    }
    
    /// Extract potential time strings from scan result
    /// - Parameter result: ScheduleScanResult
    /// - Returns: Array of potential time strings
    func extractTimes(from result: ScheduleScanResult) -> [String] {
        let fullText = extractFullText(from: result)
        return ScheduleOCRProcessor.extractTimes(from: fullText)
    }
    
    // MARK: - Parsing
    
    /// Parse scan result into structured match data
    /// - Parameter result: ScheduleScanResult from OCR
    /// - Returns: Array of extracted match data
    func parseSchedule(from result: ScheduleScanResult) -> [ExtractedMatchData] {
        // Detect table structure
        let structure = ScheduleTableParser.detectTableStructure(from: result.textBlocks)
        
        // Identify columns
        let columns = ScheduleTableParser.identifyColumns(from: structure)
        
        // Extract matches
        let extractedMatches = ScheduleTableParser.extractMatches(
            from: structure,
            columns: columns,
            baseDate: Date()
        )
        
        return extractedMatches
    }
    
    /// Convert extracted match data to MatchDraft format
    /// - Parameters:
    ///   - extractedData: Array of extracted match data
    ///   - baseDate: Base date for scheduling
    ///   - defaultAllianceColor: Default alliance color
    /// - Returns: Array of MatchDraft
    func convertToMatchDrafts(
        from extractedData: [ExtractedMatchData],
        baseDate: Date = Date(),
        defaultAllianceColor: AllianceColor = .red
    ) -> [MatchDraft] {
        return ScheduleDataMapper.mapToMatchDrafts(
            from: extractedData,
            baseDate: baseDate,
            defaultAllianceColor: defaultAllianceColor
        )
    }
    
    // MARK: - Utility
    
    /// Reset service state
    func reset() {
        isProcessing = false
        processingProgress = 0.0
        errorMessage = nil
        lastScanResult = nil
    }
}
