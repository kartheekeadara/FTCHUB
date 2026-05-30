//
//  SegmentedPillToggle.swift
//  FTCHUB
//

import SwiftUI

struct SegmentedPillSegment: Identifiable, Equatable {
    let id: String
    let title: String
    var subtitle: String? = nil
    var selectedColor: Color = DesignSystem.Colors.primary
}

struct SegmentedPillToggle: View {
    let segments: [SegmentedPillSegment]
    @Binding var selectedID: String
    var onSelect: ((String) -> Void)? = nil
    
    private let trackCornerRadius: CGFloat = 24
    private let segmentCornerRadius: CGFloat = 20
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments) { segment in
                segmentButton(for: segment)
            }
        }
        .padding(4)
        .background(DesignSystem.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: trackCornerRadius))
    }
    
    private func segmentButton(for segment: SegmentedPillSegment) -> some View {
        let isSelected = selectedID == segment.id
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedID = segment.id
            }
            onSelect?(segment.id)
        } label: {
            Group {
                if let subtitle = segment.subtitle {
                    VStack(spacing: 4) {
                        Text(segment.title)
                            .font(.system(size: 14, weight: .medium))
                        Text(subtitle)
                            .font(.system(size: 11, weight: .regular))
                    }
                } else {
                    Text(segment.title)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.textOnPrimary : DesignSystem.Colors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: segmentCornerRadius)
                    .fill(isSelected ? segment.selectedColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
