import SwiftUI

struct SetupWizardView: View {
    @State private var enableRealTimeMonitoring = true
    @State private var enableEmailAlerts = false
    @State private var enableWebhookAlerts = false
    @State private var webhookURL = ""
    @State private var emailAddress = ""
    
    var onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Setup MacGuardian Suite", icon: "gearshape.fill")
                
                Text("Configure your security monitoring preferences")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeTextSecondary)
                    .padding(.bottom)
                
                // Real-Time Monitoring
                CardContainer {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Real-Time Monitoring")
                                .font(.macGuardianTitle3)
                            Spacer()
                            Toggle("", isOn: $enableRealTimeMonitoring)
                        }
                        
                        Text("Continuously monitor file changes, processes, and network connections")
                            .font(.macGuardianCaption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                
                // Email Alerts
                CardContainer {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Email Alerts")
                                .font(.macGuardianTitle3)
                            Spacer()
                            Toggle("", isOn: $enableEmailAlerts)
                        }
                        
                        if enableEmailAlerts {
                            TextField("Email address", text: $emailAddress)
                                .textFieldStyle(.roundedBorder)
                                .transition(.opacity)
                        }
                    }
                }
                
                // Webhook Alerts
                CardContainer {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Webhook Alerts")
                                .font(.macGuardianTitle3)
                            Spacer()
                            Toggle("", isOn: $enableWebhookAlerts)
                        }
                        
                        if enableWebhookAlerts {
                            TextField("Webhook URL", text: $webhookURL)
                                .textFieldStyle(.roundedBorder)
                                .transition(.opacity)
                        }
                    }
                }
                
                // Continue button
                Button {
                    saveSettings()
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.macGuardianSubtitle)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themePurple)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.top)
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
    }
    
    private func saveSettings() {
        // Save to UserDefaults or config file
        UserDefaults.standard.set(enableRealTimeMonitoring, forKey: "enableRealTimeMonitoring")
        UserDefaults.standard.set(enableEmailAlerts, forKey: "enableEmailAlerts")
        UserDefaults.standard.set(enableWebhookAlerts, forKey: "enableWebhookAlerts")
        if !emailAddress.isEmpty {
            UserDefaults.standard.set(emailAddress, forKey: "alertEmail")
        }
        if !webhookURL.isEmpty {
            UserDefaults.standard.set(webhookURL, forKey: "webhookURL")
        }
    }
}

