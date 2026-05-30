//
//  OrderItemRowView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct OrderItemRowView: View {
    let item: OrderItem
    var onDelete: (() -> Void)? = nil
    var showDelete: Bool = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Item Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(item.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Qty: \(item.quantity)")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("@ \(item.displayUnitPrice)")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Total Price
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.displayTotalPrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if !item.isValid {
                    Text("Mismatch")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            
            // Delete Button
            if showDelete, let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(DesignSystem.Colors.error)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

#Preview {
    List {
        OrderItemRowView(item: OrderItem.sample, showDelete: true)
        OrderItemRowView(item: OrderItem.sampleItems[1])
    }
}

