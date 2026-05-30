//
//  DynamicScoutingFormView.swift
//  FTCHUB
//
//  Created on 11/16/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DynamicScoutingFormView: View {
    let template: ScoutingTemplate
    @EnvironmentObject var scoutingService: ScoutingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var formData: [UUID: String] = [:] // Field ID -> Value
    @State private var isSubmitting = false
    @State private var scoutedTeamNumber: String = ""
    @State private var matchNumber: String = ""
    @State private var eventName: String = ""
    @State private var allianceColor: String = "Red"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Basic Match Info
                    basicInfoSection
                    
                    // Dynamic Form Sections
                    if template.templateData.sections.isEmpty {
                        // No sections in template
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.Colors.error)
                            Text("This template has no sections")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text("Please add sections to this template before creating reports.")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(DesignSystem.Spacing.xl)
                    } else {
                        ForEach(template.templateData.sections.sorted(by: { $0.order < $1.order })) { section in
                            DynamicFormSection(section: section, formData: $formData)
                        }
                    }
                    
                    // Submit Button
                    submitButton
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .onAppear {
                DebugLog.log("DEBUG: DynamicScoutingFormView onAppear - Template: \(template.name), Sections: \(template.templateData.sections.count), Fields: \(template.templateData.sections.reduce(0) { $0 + $1.fields.count })")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Gradients.primary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignSystem.Gradients.primary)
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(template.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let description = template.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
        }
        .padding(.top, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.md)
    }
    
    private var basicInfoSection: some View {
        FormCardView(title: "Match Information", icon: "info.circle.fill") {
            VStack(spacing: DesignSystem.Spacing.md) {
                CustomTextField(
                    title: "Team Number",
                    text: $scoutedTeamNumber,
                    placeholder: "e.g., 12345",
                    keyboardType: .numberPad
                )
                
                CustomTextField(
                    title: "Match Number",
                    text: $matchNumber,
                    placeholder: "e.g., Q1, SF1-2"
                )
                
                CustomTextField(
                    title: "Event Name",
                    text: $eventName,
                    placeholder: "Optional"
                )
                
                Picker("Alliance Color", selection: $allianceColor) {
                    Text("Red").tag("Red")
                    Text("Blue").tag("Blue")
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var submitButton: some View {
        Button {
            Task {
                await submitForm()
            }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(isSubmitting ? "Submitting..." : "Submit Report")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? DesignSystem.Gradients.primary : DesignSystem.Gradients.secondary)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .disabled(!isFormValid || isSubmitting)
        .padding(.bottom, DesignSystem.Spacing.xl)
    }
    
    private var isFormValid: Bool {
        !scoutedTeamNumber.isEmpty && !matchNumber.isEmpty
    }
    
    private func submitForm() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        // Build report data from form
        var reportData: [String: String] = [
            "Alliance Color": allianceColor
        ]
        
        // Add all form field values
        for section in template.templateData.sections {
            for field in section.fields {
                if let value = formData[field.id] {
                    reportData[field.title] = value
                } else if field.isRequired {
                    reportData[field.title] = ""
                }
            }
        }
        
        guard let teamId = scoutingService.currentTeamId else {
            scoutingService.errorMessage = "Join or create a team before submitting reports."
            return
        }
        
        let newReport = ScoutingReport(
            id: UUID(),
            teamId: teamId,
            templateId: template.id,
            scoutedTeamNumber: scoutedTeamNumber,
            matchNumber: matchNumber,
            eventName: eventName.isEmpty ? nil : eventName,
            phase: .teleop,
            scoutId: nil,
            reportData: reportData,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await scoutingService.createScoutingReport(report: newReport)
            
            #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
            
            dismiss()
        } catch {
            // Error handled by service
        }
    }
}

// MARK: - Dynamic Form Section

struct DynamicFormSection: View {
    let section: ScoutingSection
    @Binding var formData: [UUID: String]
    
    var body: some View {
        FormCardView(title: section.title, icon: "list.bullet.rectangle") {
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(section.fields.sorted(by: { $0.order < $1.order })) { field in
                    DynamicFormField(field: field, value: Binding(
                        get: { formData[field.id] ?? "" },
                        set: { formData[field.id] = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
        }
    }
}

// MARK: - Dynamic Form Field

struct DynamicFormField: View {
    let field: ScoutingField
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(field.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if field.isRequired {
                    Text("*")
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            
            if let description = field.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            fieldView
        }
    }
    
    @ViewBuilder
    private var fieldView: some View {
        switch field.type {
        case .text:
            TextField("Enter \(field.title.lowercased())", text: $value)
                .textFieldStyle(CustomTextFieldStyle())
            
        case .number:
            HStack {
                Text("Value:")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button {
                        let current = Int(value) ?? Int(field.minValue ?? 0)
                        let min = Int(field.minValue ?? 0)
                        if current > min {
                            value = String(current - 1)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor((Int(value) ?? Int(field.minValue ?? 0)) > Int(field.minValue ?? 0) ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                    }
                    .disabled((Int(value) ?? Int(field.minValue ?? 0)) <= Int(field.minValue ?? 0))
                    
                    TextField("0", text: $value)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomTextFieldStyle())
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        let current = Int(value) ?? Int(field.minValue ?? 0)
                        let max = Int(field.maxValue ?? 100)
                        if current < max {
                            value = String(current + 1)
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor((Int(value) ?? Int(field.minValue ?? 0)) < Int(field.maxValue ?? 100) ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                    }
                    .disabled((Int(value) ?? Int(field.minValue ?? 0)) >= Int(field.maxValue ?? 100))
                }
            }
            
        case .slider:
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                let doubleValue = Binding(
                    get: { Double(value) ?? (field.minValue ?? 0) },
                    set: { value = String(Int($0)) }
                )
                
                Slider(
                    value: doubleValue,
                    in: (field.minValue ?? 0)...(field.maxValue ?? 10),
                    step: field.step ?? 1
                )
                
                HStack {
                    if let min = field.minValue {
                        Text("\(Int(min))")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                    Text("\(Int(doubleValue.wrappedValue))")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.primary)
                    Spacer()
                    if let max = field.maxValue {
                        Text("\(Int(max))")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
        case .multipleChoice:
            if let options = field.options, !options.isEmpty {
                Picker(field.title, selection: $value) {
                    Text("Select...").tag("")
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
            
        case .boolean:
            Toggle("", isOn: Binding(
                get: { value.lowercased() == "true" || value == "1" },
                set: { value = $0 ? "true" : "false" }
            ))
            .toggleStyle(.switch)
            
        case .rating:
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        value = String(star)
                        #if canImport(UIKit)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: star <= (Int(value) ?? 0) ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundColor(star <= (Int(value) ?? 0) ? .yellow : DesignSystem.Colors.textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
                if let rating = Int(value), rating > 0 {
                    Text("\(rating)/5")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
        case .notes:
            TextEditor(text: $value)
                .frame(minHeight: 100)
                .padding(8)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        }
    }
}

// MARK: - Form Card View Helper

private struct FormCardView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(DesignSystem.Gradients.primary)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            Divider().background(DesignSystem.Colors.border)
            content
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
    }
}

#Preview {
    DynamicScoutingFormView(template: ScoutingTemplate.sample)
        .environmentObject(ScoutingService())
}

