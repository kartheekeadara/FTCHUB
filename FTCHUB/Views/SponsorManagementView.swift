//
//  SponsorManagementView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct SponsorManagementView: View {
    @State private var sponsors: [Sponsor] = Sponsor.sampleSponsors
    @State private var searchText = ""
    @State private var selectedSponsor: Sponsor?
    @State private var showingAddSponsor = false
    
    var filteredSponsors: [Sponsor] {
        if searchText.isEmpty {
            return sponsors.sorted(by: { $0.tier.sortOrder < $1.tier.sortOrder })
        }
        return sponsors.filter { sponsor in
            sponsor.name.lowercased().contains(searchText.lowercased()) ||
            sponsor.contactPerson.lowercased().contains(searchText.lowercased())
        }.sorted(by: { $0.tier.sortOrder < $1.tier.sortOrder })
    }
    
    var totalContributions: Decimal {
        sponsors.reduce(0) { $0 + $1.contributionAmount }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total Sponsors",
                            value: "\(sponsors.count)",
                            icon: "building.2.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Funding",
                            value: "$\(totalContributions.formatted())",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Sponsors by Tier
                    ForEach(SponsorTier.allCases) { tier in
                        if !filteredSponsors.filter({ $0.tier == tier }).isEmpty {
                            SponsorTierSection(
                                tier: tier,
                                sponsors: filteredSponsors.filter { $0.tier == tier },
                                onSelectSponsor: { sponsor in
                                    selectedSponsor = sponsor
                                }
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .searchable(text: $searchText, prompt: "Search sponsors...")
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sponsors")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSponsor = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $selectedSponsor) { sponsor in
                SponsorDetailView(sponsor: sponsor)
            }
            .sheet(isPresented: $showingAddSponsor) {
                AddSponsorView(sponsors: $sponsors)
            }
        }
    }
}

// MARK: - Sponsor Tier Section
struct SponsorTierSection: View {
    let tier: SponsorTier
    let sponsors: [Sponsor]
    let onSelectSponsor: (Sponsor) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(tier.rawValue, systemImage: tier.icon)
                    .font(.headline)
                    .foregroundColor(tier.color)
                Spacer()
                Text("\(sponsors.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ForEach(sponsors) { sponsor in
                SponsorCard(sponsor: sponsor)
                    .padding(.horizontal)
                    .onTapGesture {
                        onSelectSponsor(sponsor)
                    }
            }
        }
    }
}

// MARK: - Sponsor Card
struct SponsorCard: View {
    let sponsor: Sponsor
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo placeholder
            ZStack {
                Circle()
                    .fill(sponsor.tier.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text(String(sponsor.name.prefix(1)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(sponsor.tier.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sponsor.name)
                    .font(.headline)
                
                Text(sponsor.contactPerson)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Label("$\(sponsor.contributionAmount.formatted())", systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if let lastContact = sponsor.lastContactDate {
                        Label(lastContact.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Sponsor Detail View
struct SponsorDetailView: View {
    let sponsor: Sponsor
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(sponsor.tier.color.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Text(String(sponsor.name.prefix(1)))
                                .font(.system(size: 36))
                                .fontWeight(.bold)
                                .foregroundColor(sponsor.tier.color)
                        }
                        
                        Text(sponsor.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(sponsor.tier.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(sponsor.tier.color.opacity(0.2))
                            .foregroundColor(sponsor.tier.color)
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.headline)
                        
                        InfoRow(icon: "person.fill", label: "Contact Person", value: sponsor.contactPerson)
                        InfoRow(icon: "envelope.fill", label: "Email", value: sponsor.email)
                        InfoRow(icon: "phone.fill", label: "Phone", value: sponsor.phone)
                        
                        if let website = sponsor.website {
                            InfoRow(icon: "globe", label: "Website", value: website)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Contribution Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contribution Details")
                            .font(.headline)
                        
                        InfoRow(icon: "dollarsign.circle.fill", label: "Amount", value: "$\(sponsor.contributionAmount.formatted())")
                        InfoRow(icon: "calendar", label: "Since", value: sponsor.sponsorshipStartDate.formatted(date: .abbreviated, time: .omitted))
                        
                        if let lastContact = sponsor.lastContactDate {
                            InfoRow(icon: "clock.fill", label: "Last Contact", value: lastContact.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Benefits
                    if !sponsor.benefits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sponsor Benefits")
                                .font(.headline)
                            
                            ForEach(sponsor.benefits, id: \.self) { benefit in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(benefit)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Notes
                    if let notes = sponsor.notes {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Add Sponsor View
struct AddSponsorView: View {
    @Binding var sponsors: [Sponsor]
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var contactPerson = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var contributionAmount = ""
    @State private var selectedTier: SponsorTier = .bronze
    
    var body: some View {
        NavigationView {
            Form {
                Section("Sponsor Information") {
                    TextField("Company Name", text: $name)
                    TextField("Contact Person", text: $contactPerson)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Contribution") {
                    TextField("Amount", text: $contributionAmount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Tier", selection: $selectedTier) {
                        ForEach(SponsorTier.allCases) { tier in
                            Label(tier.rawValue, systemImage: tier.icon)
                                .tag(tier)
                        }
                    }
                }
            }
            .navigationTitle("Add Sponsor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSponsor()
                        dismiss()
                    }
                    .disabled(name.isEmpty || contactPerson.isEmpty)
                }
            }
        }
    }
    
    private func saveSponsor() {
        let amount = Decimal(string: contributionAmount) ?? 0
        let newSponsor = Sponsor(
            name: name,
            contactPerson: contactPerson,
            email: email,
            phone: phone,
            contributionAmount: amount,
            tier: selectedTier,
            sponsorshipStartDate: Date(),
            lastContactDate: Date(),
            benefits: selectedTier.defaultBenefits,
            website: nil,
            notes: nil
        )
        sponsors.append(newSponsor)
    }
}

// MARK: - Models
struct Sponsor: Identifiable {
    let id = UUID()
    let name: String
    let contactPerson: String
    let email: String
    let phone: String
    let contributionAmount: Decimal
    let tier: SponsorTier
    let sponsorshipStartDate: Date
    let lastContactDate: Date?
    let benefits: [String]
    let website: String?
    let notes: String?
    
    static let sampleSponsors: [Sponsor] = [
        Sponsor(
            name: "TechCorp Industries",
            contactPerson: "John Smith",
            email: "john@techcorp.com",
            phone: "(555) 123-4567",
            contributionAmount: 5000,
            tier: .platinum,
            sponsorshipStartDate: Date().addingTimeInterval(-86400 * 365),
            lastContactDate: Date().addingTimeInterval(-86400 * 30),
            benefits: ["Logo on robot", "Team banner", "Website feature", "Social media mentions"],
            website: "techcorp.com",
            notes: "Long-term sponsor, very supportive"
        ),
        Sponsor(
            name: "Local Hardware Store",
            contactPerson: "Sarah Johnson",
            email: "sarah@hardware.com",
            phone: "(555) 987-6543",
            contributionAmount: 2500,
            tier: .gold,
            sponsorshipStartDate: Date().addingTimeInterval(-86400 * 200),
            lastContactDate: Date().addingTimeInterval(-86400 * 45),
            benefits: ["Logo on robot", "Team banner"],
            website: nil,
            notes: "Provides hardware discounts"
        ),
        Sponsor(
            name: "Parent Association",
            contactPerson: "Mike Davis",
            email: "mike@school.edu",
            phone: "(555) 456-7890",
            contributionAmount: 1000,
            tier: .silver,
            sponsorshipStartDate: Date().addingTimeInterval(-86400 * 150),
            lastContactDate: Date().addingTimeInterval(-86400 * 15),
            benefits: ["Newsletter mention"],
            website: nil,
            notes: "Annual fundraising"
        )
    ]
}

enum SponsorTier: String, CaseIterable, Identifiable {
    case platinum = "Platinum"
    case gold = "Gold"
    case silver = "Silver"
    case bronze = "Bronze"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .platinum: return .purple
        case .gold: return .yellow
        case .silver: return .gray
        case .bronze: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .platinum: return "star.fill"
        case .gold: return "star.leadinghalf.filled"
        case .silver: return "star"
        case .bronze: return "star.circle"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .platinum: return 0
        case .gold: return 1
        case .silver: return 2
        case .bronze: return 3
        }
    }
    
    var defaultBenefits: [String] {
        switch self {
        case .platinum:
            return ["Logo on robot", "Team banner", "Website feature", "Social media mentions", "Event invitations"]
        case .gold:
            return ["Logo on robot", "Team banner", "Website feature"]
        case .silver:
            return ["Logo on robot", "Newsletter mention"]
        case .bronze:
            return ["Newsletter mention"]
        }
    }
}

#Preview {
    SponsorManagementView()
}

