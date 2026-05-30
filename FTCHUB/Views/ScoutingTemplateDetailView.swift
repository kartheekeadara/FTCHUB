import SwiftUI

struct ScoutingTemplateDetailView: View {
    @EnvironmentObject private var scoutingService: ScoutingService
    @Environment(\.dismiss) private var dismiss
    
    let templateId: UUID
    
    private var template: ScoutingTemplate? {
        scoutingService.scoutingTemplates.first { $0.id == templateId }
    }
    
    private var totalFields: Int {
        template?.templateData.sections.reduce(0) { $0 + $1.fields.count } ?? 0
    }
    
    var body: some View {
        Group {
            if let template = template {
                List {
                    if let description = template.description, !description.isEmpty {
                        Section("Overview") {
                            Text(description)
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }
                    
                    Section("Summary") {
                        SummaryRow(label: "Sections", value: "\(template.templateData.sections.count)")
                        SummaryRow(label: "Fields", value: "\(totalFields)")
                        SummaryRow(label: "Last Updated", value: template.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        SummaryRow(label: "Created", value: template.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    ForEach(template.templateData.sections.sorted(by: { $0.order < $1.order })) { section in
                        Section(section.title) {
                            ForEach(section.fields.sorted(by: { $0.order < $1.order })) { field in
                                TemplateFieldRow(field: field)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ContentUnavailableView {
                    Label("Template Unavailable", systemImage: "questionmark.square.dashed")
                } description: {
                    Text("This template is no longer available. It may have been deleted or you may need to refresh.")
                } actions: {
                    Button("Close") { dismiss() }
                        .primaryButtonStyle()
                }
            }
        }
        .navigationTitle(template?.name ?? "Template")
        .navigationBarTitleDisplayMode(.inline)
    }
    
}

private struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .font(.subheadline)
    }
}

private struct TemplateFieldRow: View {
    let field: ScoutingField
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.sm) {
                Image(systemName: field.type.icon)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.headline)
                Text(field.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                if field.isRequired {
                    Text("Required")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primary.opacity(0.15))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .clipShape(Capsule())
                }
            }
            
            Text(field.type.displayName)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            if let description = field.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            if let options = field.options, !options.isEmpty {
                Text("Options: \(options.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            if field.minValue != nil || field.maxValue != nil || field.step != nil {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if let min = field.minValue {
                        Text("Min: \(min.cleanValue)")
                    }
                    if let max = field.maxValue {
                        Text("Max: \(max.cleanValue)")
                    }
                    if let step = field.step {
                        Text("Step: \(step.cleanValue)")
                    }
                }
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

private extension Double {
    var cleanValue: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = self.rounded() == self ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}

