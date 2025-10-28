//
//  QRCodeService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import UIKit
import AVFoundation
import CoreImage
import SwiftUI

@MainActor
class QRCodeService: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scannedCode: String?
    @Published var errorMessage: String?
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - QR Code Generation
    func generateQRCode(for scoutingTemplate: ScoutingTemplate) -> UIImage? {
        let qrData = ScoutingQRData(
            templateId: scoutingTemplate.id,
            teamId: scoutingTemplate.teamId,
            templateName: scoutingTemplate.name,
            timestamp: Date()
        )
        
        guard let jsonData = try? JSONEncoder().encode(qrData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return generateQRCode(from: jsonString)
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        guard let output = filter.outputImage?.transformed(by: transform) else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - QR Code Scanning
    func startScanning() {
        guard !isScanning else { return }
        
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = "Camera not available"
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            errorMessage = "Failed to create video input: \(error.localizedDescription)"
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            errorMessage = "Cannot add video input to capture session"
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            errorMessage = "Cannot add metadata output to capture session"
            return
        }
        
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        self.videoPreviewLayer = videoPreviewLayer
        
        isScanning = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer = nil
        isScanning = false
    }
    
    func getVideoPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return videoPreviewLayer
    }
    
    // MARK: - QR Code Parsing
    func parseScoutingQRCode(_ qrString: String) -> ScoutingQRData? {
        guard let data = qrString.data(using: .utf8),
              let qrData = try? JSONDecoder().decode(ScoutingQRData.self, from: data) else {
            return nil
        }
        return qrData
    }
    
    func parseMatchQRCode(_ qrString: String) -> MatchQRData? {
        guard let data = qrString.data(using: .utf8),
              let qrData = try? JSONDecoder().decode(MatchQRData.self, from: data) else {
            return nil
        }
        return qrData
    }
    
    // MARK: - Match QR Code Generation
    func generateMatchQRCode(matchNumber: String, teamNumber: String, eventName: String) -> UIImage? {
        let matchData = MatchQRData(
            matchNumber: matchNumber,
            teamNumber: teamNumber,
            eventName: eventName,
            timestamp: Date()
        )
        
        guard let jsonData = try? JSONEncoder().encode(matchData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return generateQRCode(from: jsonString)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRCodeService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            scannedCode = stringValue
            stopScanning()
        }
    }
}

// MARK: - QR Code Data Models
struct ScoutingQRData: Codable {
    let templateId: UUID
    let teamId: UUID
    let templateName: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case teamId = "team_id"
        case templateName = "template_name"
        case timestamp
    }
}

struct MatchQRData: Codable {
    let matchNumber: String
    let teamNumber: String
    let eventName: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case matchNumber = "match_number"
        case teamNumber = "team_number"
        case eventName = "event_name"
        case timestamp
    }
}

