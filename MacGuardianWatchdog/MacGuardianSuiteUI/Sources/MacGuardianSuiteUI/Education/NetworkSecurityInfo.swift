import SwiftUI

struct NetworkSecurityInfo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Network Security Monitoring")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                
                Text("MacGuardian monitors your network connections to detect suspicious activity and potential threats.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("What We Monitor")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    InfoCard(
                        title: "Open Ports",
                        description: "Which ports are listening for connections. Unusual ports may indicate malware."
                    )
                    
                    InfoCard(
                        title: "Active Connections",
                        description: "What your Mac is connecting to. Suspicious IPs are flagged."
                    )
                    
                    InfoCard(
                        title: "DNS Queries",
                        description: "What domains your system is looking up. Malicious domains trigger alerts."
                    )
                    
                    InfoCard(
                        title: "ARP Table",
                        description: "Network device mappings. Changes may indicate network attacks."
                    )
                }
                
                Text("Why It Matters")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                Text("Malware often communicates with command-and-control servers or exfiltrates data. Network monitoring helps you catch these activities early.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
    }
}

struct InfoCard: View {
    let title: String
    let description: String
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.macGuardianTitle3)
                Text(description)
                    .font(.macGuardianBody)
                    .foregroundColor(.themeTextSecondary)
            }
        }
    }
}

