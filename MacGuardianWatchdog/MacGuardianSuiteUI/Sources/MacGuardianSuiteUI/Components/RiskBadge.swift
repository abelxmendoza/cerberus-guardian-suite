import SwiftUI

struct RiskBadge: View {
    let level: SecurityCard.RiskLevel
    let text: String
    
    init(level: SecurityCard.RiskLevel, text: String? = nil) {
        self.level = level
        if let text = text {
            self.text = text
        } else {
            switch level {
            case .good: self.text = "SAFE"
            case .warning: self.text = "WARN"
            case .danger: self.text = "RISK"
            case .info: self.text = "INFO"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(text)
                .font(.macGuardianCaptionBold)
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.2))
        .cornerRadius(6)
    }
    
    private var iconName: String {
        switch level {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "exclamationmark.octagon.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var badgeColor: Color {
        switch level {
        case .good: return .green
        case .warning: return .orange
        case .danger: return .red
        case .info: return .themePurple
        }
    }
}

