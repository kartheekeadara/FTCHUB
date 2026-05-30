//
//  PartCatalogDetailSheet.swift
//  FTCHUB
//
//  Detail presentation for a catalog part: hero image, specs, vendor link, add to inventory.
//

import SwiftUI
import Kingfisher

struct PartCatalogDetailSheet: View {
    let part: PartTemplate
    
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var teamService: TeamService
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @State private var quantity: Int = 1
    @State private var location: String = ""
    @State private var isAdding = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var resolvedImageURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        heroImage
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                            headerSection
                            
                            if let description = part.description, !description.isEmpty {
                                descriptionSection(description)
                            }
                            
                            if let specs = part.specifications, !specs.isEmpty {
                                specificationsSection(specs)
                            }
                            
                            vendorLinkSection
                            
                            priceDisclaimer
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .padding(.bottom, 180)
                    }
                }
                
                addToInventorySheet
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Part Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                resolvedImageURL = await PartsLibraryService.shared.resolvedImageURL(for: part)
            }
            .alert("Added to Inventory", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("\(part.name) has been added to your team's inventory.")
            }
        }
    }
    
    // MARK: - Hero Image
    
    private var heroImage: some View {
        ZStack {
            DesignSystem.Colors.tertiaryBackground
            
            if let url = resolvedImageURL ?? (part.imageURL.flatMap { URL(string: $0) }) {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFit()
                    .padding(DesignSystem.Spacing.xl)
            } else {
                Image(systemName: categoryIcon)
                    .font(.system(size: 80))
                    .foregroundColor(DesignSystem.Colors.textTertiary.opacity(0.4))
            }
        }
        .frame(height: 280)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(part.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(part.manufacturer)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if let cost = part.unitCost {
                    Text("$\(cost, specifier: "%.2f")")
                        .font(.title3.weight(.bold))
                        .foregroundColor(DesignSystem.Colors.success)
                }
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Label(part.sku, systemImage: "barcode")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                Label(part.category, systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
    }
    
    // MARK: - Description
    
    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Description")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Specifications
    
    private func specificationsSection(_ specs: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Specifications")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                ForEach(specs.keys.sorted(), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(key.capitalized)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        Text(specs[key] ?? "—")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
    
    // MARK: - Vendor Link
    
    private var vendorLinkSection: some View {
        Group {
            if let urlString = part.productURL, let url = URL(string: urlString) {
                Button {
                    openURL(url)
                } label: {
                    HStack {
                        Image(systemName: "safari")
                        Text("View on \(part.manufacturer) website")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
        }
    }
    
    // MARK: - Price Disclaimer
    
    private var priceDisclaimer: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(DesignSystem.Colors.warning)
            Text("Prices may differ; verify on vendor site before ordering.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.warning.opacity(0.08))
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
    
    // MARK: - Add to Inventory Sheet
    
    private var addToInventorySheet: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Capsule()
                .fill(DesignSystem.Colors.border)
                .frame(width: 40, height: 4)
            
            if teamService.currentTeam == nil {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("Join a team to add items to inventory")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Text("Quantity")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Button {
                                if quantity > 1 { quantity -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(quantity > 1 ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                            }
                            .disabled(quantity <= 1)
                            
                            Text("\(quantity)")
                                .font(.title3.weight(.semibold))
                                .frame(minWidth: 40)
                            
                            Button {
                                quantity += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Location")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        TextField("Optional", text: $location)
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                    
                    Button {
                        addToInventory()
                    } label: {
                        HStack {
                            if isAdding {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Inventory")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .disabled(isAdding)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.2), radius: 20, x: 0, y: -10)
        )
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Actions
    
    private func addToInventory() {
        guard let teamId = teamService.currentTeam?.id else {
            errorMessage = "No team selected"
            return
        }
        
        isAdding = true
        errorMessage = nil
        
        let newItem = PartsLibraryService.shared.createInventoryItem(
            from: part,
            teamId: teamId,
            quantity: quantity,
            location: location.isEmpty ? nil : location
        )
        
        Task {
            do {
                try await inventoryService.createInventoryItem(item: newItem)
                await MainActor.run {
                    isAdding = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAdding = false
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var categoryIcon: String {
        switch part.category.lowercased() {
        case "motors": return "bolt.circle.fill"
        case "servos": return "gear.circle.fill"
        case "sensors": return "sensor.fill"
        case "wheels": return "circle.circle.fill"
        case "electronics": return "cpu"
        case "structure": return "building.2.fill"
        case "power": return "battery.100"
        case "hardware": return "wrench.and.screwdriver.fill"
        default: return "cube.box.fill"
        }
    }
}

#Preview {
    PartCatalogDetailSheet(
        part: PartTemplate(
            sku: "REV-41-1097",
            name: "HD Hex Motor",
            manufacturer: "REV Robotics",
            partNumber: "HD Hex Motor",
            category: "Motors",
            description: "High-torque motor with integrated encoder for FTC robotics applications.",
            unitCost: 49.99,
            lowStockThreshold: 2,
            specifications: [
                "Voltage": "12V DC",
                "RPM": "6000 free speed",
                "Torque": "3.2 Nm stall",
                "Weight": "0.45 lbs"
            ],
            productURL: "https://www.revrobotics.com/rev-41-1097/"
        )
    )
    .environmentObject(InventoryService())
    .environmentObject(TeamService())
}
