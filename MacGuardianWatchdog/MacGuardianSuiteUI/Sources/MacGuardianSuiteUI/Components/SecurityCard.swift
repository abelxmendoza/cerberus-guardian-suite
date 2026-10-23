import SwiftUI

struct SecurityCard: View {
    let title: String
    let description: String
    let riskLevel: RiskLevel
    let actionTitle: String?
    let action: (() -> Void)?
    
    enum RiskLevel {
        case good
        case warning
        case danger
        case info
    }
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.macGuardianTitle3)
                            .foregroundColor(.themeText)
                        
                        Text(description)
                            .font(.macGuardianBody)
                            .foregroundColor(.themeTextSecondary)
                    }
                    
                    Spacer()
                    
                    RiskBadge(level: riskLevel)
                }
                
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.macGuardianBodyBold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(riskColor)
                }
            }
        }
        .hoverPulse()
    }
    
    private var riskColor: Color {
        switch riskLevel {
        case .good: return .green
        case .warning: return .orange
        case .danger: return .red
        case .info: return .themePurple
        }
    }
}

