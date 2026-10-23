import SwiftUI

struct FinishSetupView: View {
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .scaleOnAppear()
            
            TitleText(text: "Setup Complete!")
            
            SubtitleText(text: "MacGuardian Suite is ready to protect your system")
            
            // Features summary
            VStack(spacing: 16) {
                FeatureSummaryRow(icon: "shield.lefthalf.filled", text: "Real-time monitoring active")
                FeatureSummaryRow(icon: "eye.fill", text: "Threat detection enabled")
                FeatureSummaryRow(icon: "lock.shield.fill", text: "Security baseline created")
            }
            .padding(.horizontal, LayoutGuides.paddingXLarge)
            .fadeIn()
            
            Spacer()
            
            // Finish button
            Button {
                onFinish()
            } label: {
                Text("Get Started")
                    .font(.macGuardianSubtitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.themePurple, .themePurpleLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .hoverPulse()
            .padding(.bottom, LayoutGuides.paddingXLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBlack)
    }
}

struct FeatureSummaryRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.themePurple)
                .frame(width: 24)
            Text(text)
                .font(.macGuardianBody)
                .foregroundColor(.themeText)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundColor(.green)
        }
    }
}

