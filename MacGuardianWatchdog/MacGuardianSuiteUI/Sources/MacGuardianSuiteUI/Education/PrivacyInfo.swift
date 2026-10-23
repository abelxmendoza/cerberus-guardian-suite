import SwiftUI

struct PrivacyInfo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy & TCC Permissions")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                
                Text("TCC (Transparency, Consent, and Control) is macOS's privacy system that controls which apps can access sensitive data.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("What We Monitor")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    PermissionInfoRow(
                        name: "Full Disk Access",
                        description: "Apps that can read all your files. Malware often requests this."
                    )
                    
                    PermissionInfoRow(
                        name: "Screen Recording",
                        description: "Apps that can record your screen. High privacy risk."
                    )
                    
                    PermissionInfoRow(
                        name: "Microphone",
                        description: "Apps that can listen to your microphone."
                    )
                    
                    PermissionInfoRow(
                        name: "Camera",
                        description: "Apps that can access your camera."
                    )
                    
                    PermissionInfoRow(
                        name: "Input Monitoring",
                        description: "Apps that can see your keystrokes. Very sensitive."
                    )
                }
                
                Text("Why It Matters")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                Text("Spyware and malware often request excessive permissions. Monitoring TCC helps you spot suspicious apps before they can access your private data.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
    }
}

struct PermissionInfoRow: View {
    let name: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .foregroundColor(.themePurple)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.macGuardianBodyBold)
                Text(description)
                    .font(.macGuardianCaption)
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

