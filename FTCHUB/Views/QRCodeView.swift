//
//  QRCodeView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct QRCodeView: View {
    @StateObject private var qrService = QRCodeService()
    @State private var qrCodeText = ""
    @State private var generatedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("QR Code Generator")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("Enter text for QR code", text: $qrCodeText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: qrCodeText) { _, newValue in
                        generateQRCode()
                    }
                
                if let image = generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("QR Code")
        }
    }
    
    private func generateQRCode() {
        guard !qrCodeText.isEmpty else {
            generatedImage = nil
            return
        }
        
        generatedImage = qrService.generateQRCode(from: qrCodeText)
    }
}

struct QRCodeScannerView: UIViewRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let qrService = QRCodeService()
        
        // Set up camera preview
        qrService.startScanning()
        // Note: QR code scanning setup would be implemented here
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

#Preview {
    QRCodeView()
        .environmentObject(AuthService())
}
