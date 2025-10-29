//
//  ChartComponents.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI
import Charts

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color = .blue, trend: TrendDirection? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(trend.percentage)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(trend.color)
                }
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

enum TrendDirection {
    case up(Double)
    case down(Double)
    case neutral
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
    
    var percentage: String {
        switch self {
        case .up(let value): return "+\(Int(value))%"
        case .down(let value): return "-\(Int(value))%"
        case .neutral: return "0%"
        }
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    init(progress: Double, color: Color = .blue, lineWidth: CGFloat = 10) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - Chart Card
struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Simple Bar Chart
struct SimpleBarChart: View {
    let data: [(String, Double)]
    let color: Color
    let maxValue: Double?
    
    init(data: [(String, Double)], color: Color = .blue, maxValue: Double? = nil) {
        self.data = data
        self.color = color
        self.maxValue = maxValue
    }
    
    private var chartMaxValue: Double {
        maxValue ?? (data.map { $0.1 }.max() ?? 1)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    Spacer()
                    
                    Text("\(Int(item.1))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Rectangle()
                        .fill(color)
                        .frame(height: max(20, (item.1 / chartMaxValue) * 100))
                        .cornerRadius(4)
                    
                    Text(item.0)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 150)
    }
}

// MARK: - Percentage Bar
struct PercentageBar: View {
    let label: String
    let percentage: Double
    let color: Color
    
    init(label: String, percentage: Double, color: Color = .blue) {
        self.label = label
        self.percentage = min(max(percentage, 0), 100)
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100))
                        .cornerRadius(4)
                        .animation(.easeInOut, value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String
    let value: String?
    
    init(color: Color, label: String, value: String? = nil) {
        self.color = color
        self.label = label
        self.value = value
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
            
            if let value = value {
                Spacer()
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Metric Row
struct MetricRow: View {
    let label: String
    let value: String
    let icon: String?
    let color: Color
    
    init(label: String, value: String, icon: String? = nil, color: Color = .primary) {
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            StatCard(
                title: "Total Matches",
                value: "24",
                subtitle: "This season",
                icon: "sportscourt.fill",
                color: .blue,
                trend: .up(12.5)
            )
            
            ChartCard(title: "Match Performance", subtitle: "Last 10 matches") {
                SimpleBarChart(data: [
                    ("M1", 45),
                    ("M2", 67),
                    ("M3", 89),
                    ("M4", 56),
                    ("M5", 78)
                ], color: .green)
            }
            
            PercentageBar(label: "Win Rate", percentage: 75, color: .green)
            
            HStack(spacing: 12) {
                ZStack {
                    ProgressRing(progress: 0.75, color: .blue)
                        .frame(width: 60, height: 60)
                    Text("75%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading) {
                    Text("Completion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Season Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

