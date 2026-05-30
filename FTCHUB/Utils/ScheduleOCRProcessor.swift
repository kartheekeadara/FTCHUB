//
//  ScheduleOCRProcessor.swift
//  FTCHUB
//
//  Created for Schedule Scanning Feature - Phase 1
//  OCR processing utilities using Vision Framework
//

import Foundation
import Vision
import UIKit
import CoreGraphics
import CoreImage

/// Utility class for processing images and extracting text using OCR
@MainActor
final class ScheduleOCRProcessor {
    
    /// Upscale image if it's too small for good OCR
    /// - Parameter image: Original UIImage
    /// - Returns: Upscaled UIImage if needed
    private static func upscaleImageIfNeeded(_ image: UIImage) -> UIImage {
        let minDimension: CGFloat = 2000 // Minimum dimension for good OCR
        let size = image.size
        let maxDimension = max(size.width, size.height)
        
        if maxDimension < minDimension {
            let scale = minDimension / maxDimension
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            defer { UIGraphicsEndImageContext() }
            
            image.draw(in: CGRect(origin: .zero, size: newSize))
            return UIGraphicsGetImageFromCurrentImageContext() ?? image
        }
        
        return image
    }
    
    /// Enhance image for better OCR accuracy with multiple strategies
    /// - Parameter image: Original UIImage
    /// - Returns: Enhanced UIImage with improved contrast and sharpness
    private static func enhanceImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.useSoftwareRenderer: false, .highQualityDownsample: true])
        
        // Apply comprehensive filters for better OCR
        var processedImage = ciImage
        
        // Step 1: Convert to grayscale first (better for OCR)
        if let grayscaleFilter = CIFilter(name: "CIColorControls") {
            grayscaleFilter.setValue(processedImage, forKey: kCIInputImageKey)
            grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey)
            if let output = grayscaleFilter.outputImage {
                processedImage = output
            }
        }
        
        // Step 2: Noise reduction (reduce graininess) - use median filter as fallback
        if let noiseFilter = CIFilter(name: "CINoiseReduction") {
            noiseFilter.setValue(processedImage, forKey: kCIInputImageKey)
            if noiseFilter.inputKeys.contains("inputNoiseLevel") {
                noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
            }
            if noiseFilter.inputKeys.contains("inputSharpness") {
                noiseFilter.setValue(0.4, forKey: "inputSharpness")
            }
            if let output = noiseFilter.outputImage {
                processedImage = output
            }
        } else if let medianFilter = CIFilter(name: "CIMedianFilter") {
            // Fallback to median filter for noise reduction
            medianFilter.setValue(processedImage, forKey: kCIInputImageKey)
            if let output = medianFilter.outputImage {
                processedImage = output
            }
        }
        
        // Step 3: Increase contrast significantly
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.5, forKey: kCIInputContrastKey) // Stronger contrast
            contrastFilter.setValue(0.1, forKey: kCIInputBrightnessKey) // Slight brightness adjustment
            if let output = contrastFilter.outputImage {
                processedImage = output
            }
        }
        
        // Step 4: Sharpen the image more aggressively
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(processedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.8, forKey: kCIInputSharpnessKey) // More aggressive sharpening
            sharpenFilter.setValue(0.4, forKey: kCIInputRadiusKey)
            if let output = sharpenFilter.outputImage {
                processedImage = output
            }
        }
        
        // Step 5: Apply unsharp mask for additional clarity
        if let unsharpFilter = CIFilter(name: "CIUnsharpMask") {
            unsharpFilter.setValue(processedImage, forKey: kCIInputImageKey)
            unsharpFilter.setValue(2.5, forKey: kCIInputIntensityKey)
            unsharpFilter.setValue(1.0, forKey: kCIInputRadiusKey)
            if let output = unsharpFilter.outputImage {
                processedImage = output
            }
        }
        
        // Convert back to UIImage
        guard let outputCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    /// Create an alternative enhanced version with different settings
    private static func enhanceImageAlternative(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        
        var processedImage = ciImage
        
        // Alternative approach: High contrast black and white
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(processedImage, forKey: kCIInputImageKey)
            colorControls.setValue(0.0, forKey: kCIInputSaturationKey) // Grayscale
            colorControls.setValue(2.0, forKey: kCIInputContrastKey) // Very high contrast
            colorControls.setValue(0.0, forKey: kCIInputBrightnessKey)
            if let output = colorControls.outputImage {
                processedImage = output
            }
        }
        
        // Apply exposure adjustment
        if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
            exposureFilter.setValue(processedImage, forKey: kCIInputImageKey)
            exposureFilter.setValue(0.2, forKey: kCIInputEVKey)
            if let output = exposureFilter.outputImage {
                processedImage = output
            }
        }
        
        guard let outputCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    /// Perform OCR on an image with specific settings
    private static func performOCR(on cgImage: CGImage, request: VNRecognizeTextRequest) throws -> [VNRecognizedTextObservation] {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let results = request.results, !results.isEmpty else {
            return []
        }
        
        return results.compactMap { $0 as? VNRecognizedTextObservation }
    }
    
    /// Merge text blocks from multiple OCR passes, preferring higher confidence
    private static func mergeTextBlocks(_ blocks1: [TextBlock], _ blocks2: [TextBlock], imageSize: CGSize) -> [TextBlock] {
        var merged: [TextBlock] = []
        
        // First, add all high-confidence blocks from first pass
        for block in blocks1 {
            if block.confidence > 0.6 {
                merged.append(block)
            }
        }
        
        // Then, add blocks from second pass that don't overlap significantly with first pass
        for block2 in blocks2 {
            var overlaps = false
            for block1 in blocks1 {
                let overlap = block1.boundingBox.intersection(block2.boundingBox)
                let overlapRatio = (overlap.width * overlap.height) / max(block1.boundingBox.width * block1.boundingBox.height,
                                                                          block2.boundingBox.width * block2.boundingBox.height)
                if overlapRatio > 0.5 {
                    // Significant overlap - prefer the one with higher confidence
                    if block2.confidence > block1.confidence {
                        // Replace block1 with block2
                        if let index = merged.firstIndex(where: { $0.text == block1.text && abs($0.boundingBox.midX - block1.boundingBox.midX) < 10 }) {
                            merged[index] = block2
                        }
                    }
                    overlaps = true
                    break
                }
            }
            
            if !overlaps && block2.confidence > 0.4 {
                merged.append(block2)
            }
        }
        
        return merged
    }
    
    /// Process an image and extract text blocks using Vision Framework with multiple passes for maximum accuracy
    /// - Parameters:
    ///   - image: The UIImage to process
    ///   - language: Optional language code for OCR (default: English)
    /// - Returns: ScheduleScanResult with extracted text blocks
    /// - Throws: ScheduleScanError if processing fails
    static func processImage(_ image: UIImage, language: String = "en-US") async throws -> ScheduleScanResult {
        let startTime = Date()
        
        guard let cgImage = image.cgImage else {
            throw ScheduleScanError.invalidImage
        }
        
        // Step 1: Upscale if needed
        let upscaledImage = upscaleImageIfNeeded(image)
        
        // Step 2: Create multiple enhanced versions
        let enhancedImage1 = enhanceImage(upscaledImage) ?? upscaledImage
        let enhancedImage2 = enhanceImageAlternative(upscaledImage) ?? upscaledImage
        
        guard let enhancedCGImage1 = enhancedImage1.cgImage,
              let enhancedCGImage2 = enhancedImage2.cgImage else {
            throw ScheduleScanError.invalidImage
        }
        
        let imageSize = CGSize(width: enhancedCGImage1.width, height: enhancedCGImage1.height)
        
        // Expanded custom words for better recognition
        let customWords = [
            "Q", "Qual", "Qualification", "Match", "M", "SF", "Semifinal", "Final", "F", "Playoff", "P",
            "Red", "Blue", "Alliance", "Team", "Field", "Time", "Schedule",
            "1829", "1828", "1827", "1826", "1825" // Common team number patterns
        ]
        
        // PASS 1: Primary enhanced image with maximum accuracy settings
        let request1 = VNRecognizeTextRequest()
        request1.recognitionLevel = .accurate
        request1.usesLanguageCorrection = true
        request1.recognitionLanguages = [language]
        request1.minimumTextHeight = 0.008 // Very low threshold to catch small text
        request1.customWords = customWords
        
        var observations1: [VNRecognizedTextObservation] = []
        do {
            observations1 = try performOCR(on: enhancedCGImage1, request: request1)
        } catch {
            DebugLog.log("OCR Pass 1 error: \(error.localizedDescription)")
        }
        
        // PASS 2: Alternative enhanced image with same settings
        let request2 = VNRecognizeTextRequest()
        request2.recognitionLevel = .accurate
        request2.usesLanguageCorrection = true
        request2.recognitionLanguages = [language]
        request2.minimumTextHeight = 0.008
        request2.customWords = customWords
        
        var observations2: [VNRecognizedTextObservation] = []
        do {
            observations2 = try performOCR(on: enhancedCGImage2, request: request2)
        } catch {
            DebugLog.log("OCR Pass 2 error: \(error.localizedDescription)")
        }
        
        // Combine observations from both passes
        let allObservations = observations1 + observations2
        
        guard !allObservations.isEmpty else {
            throw ScheduleScanError.noTextDetected
        }
        
        // Convert observations to text blocks - use top 5 candidates for maximum accuracy
        var textBlocks: [TextBlock] = []
        var totalConfidence: Double = 0.0
        var confidenceCount: Int = 0
        var seenTexts = Set<String>() // Track to avoid exact duplicates
        
        for observation in allObservations {
            // Get top 5 candidates for better accuracy
            let candidates = observation.topCandidates(5)
            guard let bestCandidate = candidates.first else { continue }
            
            // Intelligent candidate selection
            var selectedCandidate = bestCandidate
            var bestScore: Double = Double(bestCandidate.confidence)
            
            for candidate in candidates {
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Score based on confidence and validity
                var score = Double(candidate.confidence)
                
                // Boost score if it looks like valid data
                if !extractTeamNumbers(from: text).isEmpty {
                    score += 0.2 // Team numbers are important
                }
                if !extractMatchNumbers(from: text).isEmpty {
                    score += 0.2 // Match numbers are important
                }
                if text.count >= 2 && text.count <= 10 {
                    score += 0.1 // Reasonable length
                }
                
                // Penalize if it's just punctuation or single characters
                if text.count == 1 && !text.first!.isNumber && !text.first!.isLetter {
                    score -= 0.5
                }
                
                if score > bestScore {
                    bestScore = score
                    selectedCandidate = candidate
                }
            }
            
            let text = selectedCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            let confidence = Double(selectedCandidate.confidence)
            
            // Skip duplicates
            let textKey = text.lowercased().replacingOccurrences(of: " ", with: "")
            if seenTexts.contains(textKey) && confidence < 0.8 {
                continue
            }
            seenTexts.insert(textKey)
            
            // Skip very low confidence results unless they're clearly valid
            if confidence < 0.25 {
                let isLikelyValid = !extractTeamNumbers(from: text).isEmpty ||
                                   !extractMatchNumbers(from: text).isEmpty ||
                                   (text.count >= 2 && text.count <= 15 && text.first?.isNumber != nil)
                if !isLikelyValid {
                    continue
                }
            }
            
            // Normalize bounding box to image coordinates
            let boundingBox = observation.boundingBox
            
            // Convert Vision's normalized coordinates (0,0 bottom-left) to UIKit (0,0 top-left)
            let rect = CGRect(
                x: boundingBox.origin.x * imageSize.width,
                y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                width: boundingBox.width * imageSize.width,
                height: boundingBox.height * imageSize.height
            )
            
            let textBlock = TextBlock(
                text: text,
                boundingBox: rect,
                confidence: confidence
            )
            
            textBlocks.append(textBlock)
            totalConfidence += confidence
            confidenceCount += 1
        }
        
        // Remove near-duplicates based on position
        var deduplicatedBlocks: [TextBlock] = []
        for block in textBlocks.sorted(by: { $0.confidence > $1.confidence }) {
            var isDuplicate = false
            for existing in deduplicatedBlocks {
                let distance = sqrt(pow(block.boundingBox.midX - existing.boundingBox.midX, 2) +
                                   pow(block.boundingBox.midY - existing.boundingBox.midY, 2))
                if distance < 20 && abs(block.text.count - existing.text.count) <= 2 {
                    // Very close position and similar length - likely duplicate
                    if block.confidence <= existing.confidence {
                        isDuplicate = true
                        break
                    }
                }
            }
            if !isDuplicate {
                deduplicatedBlocks.append(block)
            }
        }
        
        textBlocks = deduplicatedBlocks
        
        // Calculate overall confidence
        let overallConfidence = confidenceCount > 0 ? totalConfidence / Double(confidenceCount) : 0.0
        
        // Calculate processing time
        let processingTime = Date().timeIntervalSince(startTime)
        let processingTimeMs = Int(processingTime * 1000)
        
        // Check if we got any results
        guard !textBlocks.isEmpty else {
            throw ScheduleScanError.noTextDetected
        }
        
        return ScheduleScanResult(
            textBlocks: textBlocks,
            overallConfidence: overallConfidence,
            processingTimeMs: processingTimeMs,
            imageSize: imageSize
        )
    }
    
    /// Clean and normalize text extracted from OCR
    /// - Parameter text: Raw OCR text
    /// - Returns: Cleaned text
    static func cleanText(_ text: String) -> String {
        // Remove extra whitespace
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace multiple spaces with single space
        let normalized = cleaned.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        
        return normalized
    }
    
    /// Group text blocks by proximity to identify rows
    /// - Parameters:
    ///   - textBlocks: Array of text blocks
    ///   - rowThreshold: Vertical distance threshold for grouping (in points)
    /// - Returns: Array of text block arrays, each representing a row
    static func groupIntoRows(_ textBlocks: [TextBlock], rowThreshold: CGFloat = 30.0) -> [[TextBlock]] {
        guard !textBlocks.isEmpty else { return [] }
        
        // Sort blocks by Y position (top to bottom)
        let sortedBlocks = textBlocks.sorted { block1, block2 in
            block1.boundingBox.midY < block2.boundingBox.midY
        }
        
        var rows: [[TextBlock]] = []
        var currentRow: [TextBlock] = []
        var lastY: CGFloat?
        
        for block in sortedBlocks {
            let currentY = block.boundingBox.midY
            
            if let lastY = lastY {
                // Check if this block is in the same row
                if abs(currentY - lastY) <= rowThreshold {
                    currentRow.append(block)
                } else {
                    // New row
                    if !currentRow.isEmpty {
                        rows.append(currentRow.sorted { $0.boundingBox.midX < $1.boundingBox.midX })
                        currentRow = []
                    }
                    currentRow.append(block)
                }
            } else {
                // First block
                currentRow.append(block)
            }
            
            lastY = currentY
        }
        
        // Add the last row
        if !currentRow.isEmpty {
            rows.append(currentRow.sorted { $0.boundingBox.midX < $1.boundingBox.midX })
        }
        
        return rows
    }
    
    /// Extract potential match numbers from text
    /// - Parameter text: Text to search
    /// - Returns: Array of potential match number strings
    static func extractMatchNumbers(from text: String) -> [String] {
        // Patterns for match numbers:
        // Q1, Q2, Q-1, Q-2, Qual 1, Qualification 27, Match 1, M1, M-1, SF1-1, SF1-2, F1, F2, etc.
        let patterns = [
            #"(?i)(?:Q|Qual|Qualification)\s+(\d+)"#,      // Qualification 27, Qual 27, Q 27
            #"(?i)(?:Q|Qual)\s*-?\s*(\d+)"#,                // Q1, Q-1, Qual 1
            #"(?i)(?:M|Match)\s+(\d+)"#,                    // Match 1
            #"(?i)(?:M|Match)\s*-?\s*(\d+)"#,               // M1, M-1
            #"(?i)SF(\d+)-(\d+)"#,                          // SF1-1, SF1-2
            #"(?i)F(?:inal)?\s+(\d+)"#,                     // Final 1
            #"(?i)F(?:inal)?\s*-?\s*(\d+)"#,                // F1, F2
            #"(?i)P(?:layoff)?\s+(\d+)"#,                   // Playoff 1
            #"(?i)P(?:layoff)?\s*-?\s*(\d+)"#                // P1, P-1
        ]
        
        var matchNumbers: [String] = []
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let results = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for result in results ?? [] {
                if result.numberOfRanges > 1 {
                    let fullMatch = nsString.substring(with: result.range)
                    // Normalize to consistent format (e.g., "Qualification 27" -> "Q27")
                    let normalized = normalizeMatchNumber(fullMatch)
                    matchNumbers.append(normalized)
                }
            }
        }
        
        return Array(Set(matchNumbers)) // Remove duplicates
    }
    
    /// Normalizes match number strings to a consistent format
    /// - Parameter matchNumber: Raw match number string
    /// - Returns: Normalized match number (e.g., "Qualification 27" -> "Q27")
    static func normalizeMatchNumber(_ matchNumber: String) -> String {
        var normalized = matchNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Normalize "Qualification" to "Q"
        normalized = normalized.replacingOccurrences(
            of: #"(?i)Qualification\s+(\d+)"#,
            with: "Q$1",
            options: .regularExpression
        )
        
        // Normalize "Qual" to "Q"
        normalized = normalized.replacingOccurrences(
            of: #"(?i)Qual\s+(\d+)"#,
            with: "Q$1",
            options: .regularExpression
        )
        
        // Normalize "Semifinal" to "SF"
        normalized = normalized.replacingOccurrences(
            of: #"(?i)Semifinal\s+(\d+)"#,
            with: "SF$1",
            options: .regularExpression
        )
        
        // Normalize "Final" to "F"
        normalized = normalized.replacingOccurrences(
            of: #"(?i)Final\s+(\d+)"#,
            with: "F$1",
            options: .regularExpression
        )
        
        // Remove extra spaces
        normalized = normalized.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
        
        return normalized
    }
    
    /// Extract potential team numbers from text
    /// - Parameter text: Text to search
    /// - Returns: Array of potential team number strings (4-5 digits)
    static func extractTeamNumbers(from text: String) -> [String] {
        // Pattern for team numbers: 4-5 digit numbers
        let pattern = #"\b(\d{4,5})\b"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        return results.compactMap { result in
            guard result.numberOfRanges > 1 else { return nil }
            let teamNumber = nsString.substring(with: result.range(at: 1))
            // Filter out common false positives (years, times, etc.)
            let number = Int(teamNumber) ?? 0
            if number >= 1 && number <= 99999 {
                return teamNumber
            }
            return nil
        }
    }
    
    /// Extract potential time strings from text
    /// - Parameter text: Text to search
    /// - Returns: Array of potential time strings
    static func extractTimes(from text: String) -> [String] {
        // Patterns for times:
        // 12-hour: 10:30 AM, 2:45 PM, 10:30am
        // 24-hour: 10:30, 14:30, 10:30:00
        let patterns = [
            #"\b(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm))\b"#,  // 12-hour format
            #"\b(\d{1,2}:\d{2}(?::\d{2})?)\b"#           // 24-hour format
        ]
        
        var times: [String] = []
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let results = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for result in results ?? [] {
                if result.numberOfRanges > 1 {
                    let time = nsString.substring(with: result.range(at: 1))
                    times.append(time)
                }
            }
        }
        
        return Array(Set(times)) // Remove duplicates
    }
}
