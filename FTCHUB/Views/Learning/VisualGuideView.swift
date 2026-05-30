//
//  VisualGuideView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct VisualGuideView: View {
    let guide: VisualGuide
    let moduleColor: Color
    @State private var selectedElement: InteractiveElement?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "eye.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text(guide.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            // Description
            Text(guide.description)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
            
            // Visual content
            if let imageName = guide.imageName {
                ZStack {
                    // Try to load image, fallback to placeholder if not found
                    Group {
                        if let image = UIImage(named: imageName) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            // Placeholder for missing images
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text("Visual diagram")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(DesignSystem.Colors.secondaryBackground)
                        }
                    }
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    
                    // Interactive elements overlay
                    if !guide.interactiveElements.isEmpty {
                        GeometryReader { geometry in
                            ForEach(guide.interactiveElements) { element in
                                InteractiveElementButton(
                                    element: element,
                                    geometry: geometry,
                                    isSelected: selectedElement?.id == element.id
                                ) {
                                    selectedElement = selectedElement?.id == element.id ? nil : element
                                    DesignSystem.Haptics.selection()
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            } else {
                // No image, show interactive elements on placeholder
                if !guide.interactiveElements.isEmpty {
                    ZStack {
                        VStack {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 48))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Text("Interactive Diagram")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        
                        GeometryReader { geometry in
                            ForEach(guide.interactiveElements) { element in
                                InteractiveElementButton(
                                    element: element,
                                    geometry: geometry,
                                    isSelected: selectedElement?.id == element.id
                                ) {
                                    selectedElement = selectedElement?.id == element.id ? nil : element
                                    DesignSystem.Haptics.selection()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
            }
            
            // Selected element info
            if let selected = selectedElement {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selected.label)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(selected.description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding()
                .background(moduleColor.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.md)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding()
    }
}

// MARK: - Interactive Element Button
struct InteractiveElementButton: View {
    let element: InteractiveElement
    let geometry: GeometryProxy
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.6))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 32, height: 32)
            )
        }
        .position(
            x: geometry.size.width * element.position.x,
            y: geometry.size.height * element.position.y
        )
    }
}

