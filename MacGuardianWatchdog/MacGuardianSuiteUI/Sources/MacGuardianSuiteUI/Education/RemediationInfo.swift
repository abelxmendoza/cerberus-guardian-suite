import SwiftUI

struct RemediationInfo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Automated Remediation")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                
                Text("When MacGuardian detects a threat, it can automatically take action to protect your system.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("What Happens Automatically")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    RemediationCard(
                        title: "Suspicious Process",
                        action: "Terminated automatically",
                        description: "High CPU processes connecting to known malicious IPs are stopped immediately."
                    )
                    
                    RemediationCard(
                        title: "Ransomware Detection",
                        action: "Network isolation",
                        description: "When mass file changes are detected, network connections are blocked to prevent data exfiltration."
                    )
                    
                    RemediationCard(
                        title: "Malicious Network Connection",
                        action: "Firewall rule added",
                        description: "Connections to known threat IPs are blocked at the firewall level."
                    )
                }
                
                Text("You're Always in Control")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                Text("All automatic actions are logged and you can review them in the Remediation Center. You can also configure which actions should be automatic vs. requiring your approval.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
    }
}

struct RemediationCard: View {
    let title: String
    let action: String
    let description: String
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.macGuardianTitle3)
                    Spacer()
                    Text(action)
                        .font(.macGuardianCaptionBold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(6)
                }
                Text(description)
                    .font(.macGuardianBody)
                    .foregroundColor(.themeTextSecondary)
            }
        }
    }
}

