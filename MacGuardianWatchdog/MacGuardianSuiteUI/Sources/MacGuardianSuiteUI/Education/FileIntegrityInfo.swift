import SwiftUI

struct FileIntegrityInfo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("What is File Integrity Monitoring?")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                
                Text("File Integrity Monitoring (FIM) is a security feature that continuously watches your important files and folders for unauthorized changes.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("How It Works")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    InfoBullet(text: "MacGuardian creates a baseline (fingerprint) of your files")
                    InfoBullet(text: "It continuously monitors for changes to file contents, permissions, or deletion")
                    InfoBullet(text: "When changes are detected, you're immediately alerted")
                    InfoBullet(text: "You can review what changed and decide if it's legitimate")
                }
                
                Text("Why It Matters")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                Text("Malware often modifies system files or installs itself in hidden locations. File Integrity Monitoring helps you catch these changes before they cause serious damage.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("Example")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If a file in /System/Library suddenly changes:")
                            .font(.macGuardianBodyBold)
                        Text("• MacGuardian detects the change")
                        Text("• Alerts you immediately")
                        Text("• Shows what was modified")
                        Text("• Helps you determine if it's legitimate")
                    }
                }
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
    }
}

struct InfoBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.themePurple)
                .padding(.top, 6)
            Text(text)
                .font(.macGuardianBody)
                .foregroundColor(.themeText)
        }
    }
}

