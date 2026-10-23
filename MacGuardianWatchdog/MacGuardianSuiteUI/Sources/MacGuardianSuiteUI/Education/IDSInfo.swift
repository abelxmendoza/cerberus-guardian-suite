import SwiftUI

struct IDSInfo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Intrusion Detection System (IDS)")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                
                Text("An IDS correlates multiple security events to detect complex attack patterns that individual alerts might miss.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("How Correlation Works")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                CardContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Example Rule:")
                            .font(.macGuardianBodyBold)
                        Text("If file changes + new process + network connection happen together within 60 seconds → CRITICAL ALERT")
                            .font(.macGuardianBody)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                
                Text("Why Individual Alerts Aren't Enough")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    InfoBullet(text: "A single file change might be normal")
                    InfoBullet(text: "A new process might be legitimate")
                    InfoBullet(text: "A network connection could be expected")
                    InfoBullet(text: "But all three together? That's suspicious!")
                }
                
                Text("Correlation Rules")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                Text("MacGuardian uses predefined rules to detect attack patterns. These rules look for combinations of events that indicate malicious activity.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
    }
}

