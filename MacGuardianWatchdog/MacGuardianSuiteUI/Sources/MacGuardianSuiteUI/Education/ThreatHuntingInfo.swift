import SwiftUI

struct ThreatHuntingInfo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Threat Hunting")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                
                Text("Threat hunting proactively searches for hidden threats that traditional security tools might miss.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("What We Look For")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    ThreatInfoCard(
                        title: "Hidden Processes",
                        description: "Processes that try to hide from normal process lists. Malware often uses this technique."
                    )
                    
                    ThreatInfoCard(
                        title: "Persistence Mechanisms",
                        description: "Ways malware ensures it starts automatically. We check LaunchAgents, LaunchDaemons, and cron jobs."
                    )
                    
                    ThreatInfoCard(
                        title: "Suspicious Binaries",
                        description: "Executable files in unusual locations or with suspicious signatures."
                    )
                    
                    ThreatInfoCard(
                        title: "Unusual Behavior",
                        description: "Processes using excessive CPU, making unexpected network connections, or accessing sensitive files."
                    )
                }
                
                Text("How It Works")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                Text("MacGuardian uses behavioral analysis and signature detection to identify potential threats. When something suspicious is found, you're alerted with details about what was detected and why it's concerning.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
    }
}

struct ThreatInfoCard: View {
    let title: String
    let description: String
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.red)
                    Text(title)
                        .font(.macGuardianTitle3)
                }
                Text(description)
                    .font(.macGuardianBody)
                    .foregroundColor(.themeTextSecondary)
            }
        }
    }
}

