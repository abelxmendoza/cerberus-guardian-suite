import SwiftUI

struct BaselineCreationView: View {
    @State private var progress: Double = 0.0
    @State private var currentStep = "Initializing..."
    @State private var completedSteps: [String] = []
    
    let steps = [
        "Scanning file system",
        "Analyzing user accounts",
        "Checking SSH configuration",
        "Building process baseline",
        "Creating network baseline",
        "Finalizing security profile"
    ]
    
    var onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Progress indicator
            VStack(spacing: 24) {
                ProgressRing(progress: progress, size: 150)
                
                Text("Creating Security Baseline")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                
                Text(currentStep)
                    .font(.macGuardianBody)
                    .foregroundColor(.themeTextSecondary)
            }
            .fadeIn()
            
            // Steps list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(steps, id: \.self) { step in
                    StepRow(
                        step: step,
                        isCompleted: completedSteps.contains(step),
                        isCurrent: currentStep == step
                    )
                }
            }
            .padding(.horizontal, LayoutGuides.paddingXLarge)
            .fadeIn()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBlack)
        .onAppear {
            startBaselineCreation()
        }
    }
    
    private func startBaselineCreation() {
        var stepIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if stepIndex < steps.count {
                currentStep = steps[stepIndex]
                progress = Double(stepIndex + 1) / Double(steps.count)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completedSteps.append(steps[stepIndex])
                }
                
                stepIndex += 1
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

struct StepRow: View {
    let step: String
    let isCompleted: Bool
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if isCurrent {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.themeTextSecondary)
            }
            
            Text(step)
                .font(.macGuardianBody)
                .foregroundColor(isCompleted || isCurrent ? .themeText : .themeTextSecondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

