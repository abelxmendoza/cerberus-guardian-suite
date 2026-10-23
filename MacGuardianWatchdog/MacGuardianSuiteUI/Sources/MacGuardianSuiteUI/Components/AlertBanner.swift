import SwiftUI

struct AlertBanner: View {
    let message: String
    let severity: AlertSeverity
    let actionTitle: String?
    let action: (() -> Void)?
    
    enum AlertSeverity {
        case info
        case warning
        case critical
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(severityColor)
            
            Text(message)
                .font(.macGuardianBody)
                .foregroundColor(.themeText)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .tint(severityColor)
            }
        }
        .padding(LayoutGuides.paddingMedium)
        .background(severityColor.opacity(0.15))
        .overlay(
            Rectangle()
                .fill(severityColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity, alignment: .leading)
        )
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch severity {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    private var severityColor: Color {
        switch severity {
        case .info: return .themePurple // Base purple for info
        case .warning: return .themePurpleLight // Lighter purple for warnings
        case .critical: return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple for critical
        }
    }
}

