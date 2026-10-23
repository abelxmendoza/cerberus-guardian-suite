import SwiftUI

/// Reusable severity badge component
struct SeverityBadge: View {
    let severity: String
    let showIcon: Bool
    
    init(severity: String, showIcon: Bool = true) {
        self.severity = severity
        self.showIcon = showIcon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: severityIcon)
                    .font(.caption2)
            }
            Text(severity.uppercased())
                .font(.caption.bold())
        }
        .foregroundColor(severityColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(severityColor.opacity(0.2))
        .cornerRadius(6)
    }
    
    private var severityColor: Color {
        switch severity.lowercased() {
        case "critical": return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple
        case "high": return Color(red: 0.8, green: 0.3, blue: 0.5) // Purple-red blend
        case "warning", "medium": return .themePurpleLight // Lighter purple
        case "low", "info": return .themePurple // Base purple
        default: return .themeTextSecondary
        }
    }
    
    private var severityIcon: String {
        switch severity.lowercased() {
        case "critical": return "exclamationmark.triangle.fill"
        case "high": return "exclamationmark.circle.fill"
        case "warning", "medium": return "exclamationmark.triangle"
        default: return "info.circle.fill"
        }
    }
}

