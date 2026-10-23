import SwiftUI

enum BlueTeamCharts {
    struct SystemStatsGrid: View {
        let stats: SystemStats
        
        var body: some View {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(name: "CPU", value: stats.cpu, unit: "%", color: .blue)
                StatCard(name: "Memory", value: stats.memory, unit: "%", color: .green)
                StatCard(name: "Disk", value: stats.disk, unit: "%", color: .orange)
                StatCard(name: "Net Out", value: stats.networkOut, unit: "MB/s", color: .purple)
                StatCard(name: "Net In", value: stats.networkIn, unit: "MB/s", color: .cyan)
            }
        }
    }
    
    struct StatCard: View {
        let name: String
        let value: Double
        let unit: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                Text(name)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", value))
                        .font(.title2.bold())
                        .foregroundColor(.themeText)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.themeDarkGray)
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * min(CGFloat(value / 100.0), 1.0), height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
            .padding()
            .background(Color.themeDarkGray)
            .cornerRadius(12)
        }
    }
    
    struct EventRow: View {
        let event: ThreatEvent
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(colorFor(event.severity))
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.themeText)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label(event.source, systemImage: "tag.fill")
                            .font(.caption2)
                            .foregroundColor(.themeTextSecondary)
                        
                        Text(event.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.themeTextSecondary)
                        
                        if let category = event.category {
                            Text(category)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.themePurple.opacity(0.2))
                                .foregroundColor(.themePurple)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                Text(event.severity.capitalized)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorFor(event.severity).opacity(0.2))
                    .foregroundColor(colorFor(event.severity))
                    .cornerRadius(6)
            }
            .padding(.vertical, 8)
        }
        
        func colorFor(_ severity: String) -> Color {
            switch severity.lowercased() {
            case "critical": return .red
            case "high": return .orange
            case "medium": return .yellow
            case "warning": return .yellow
            default: return .green
            }
        }
    }
    
    struct EventDetailView: View {
        let event: ThreatEvent
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(colorFor(event.severity))
                        .frame(width: 12, height: 12)
                    Text(event.severity.capitalized)
                        .font(.headline)
                        .foregroundColor(colorFor(event.severity))
                    Spacer()
                }
                
                Text(event.description)
                    .font(.body)
                    .foregroundColor(.themeText)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Source", value: event.source)
                    DetailRow(label: "Time", value: event.timestamp.formatted(date: .abbreviated, time: .shortened))
                    if let category = event.category {
                        DetailRow(label: "Category", value: category)
                    }
                }
                
                if let details = event.details, !details.isEmpty {
                    Divider()
                    Text("Details")
                        .font(.headline)
                        .foregroundColor(.themeText)
                    
                    ForEach(Array(details.keys.sorted()), id: \.self) { key in
                        if let value = details[key] {
                            DetailRow(label: key, value: value)
                        }
                    }
                }
            }
            .padding()
        }
        
        func colorFor(_ severity: String) -> Color {
            switch severity.lowercased() {
            case "critical": return .red
            case "high": return .orange
            case "medium": return .yellow
            case "warning": return .yellow
            default: return .green
            }
        }
    }
    
    struct DetailRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label + ":")
                    .font(.caption.bold())
                    .foregroundColor(.themeTextSecondary)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.themeText)
                Spacer()
            }
        }
    }
}

