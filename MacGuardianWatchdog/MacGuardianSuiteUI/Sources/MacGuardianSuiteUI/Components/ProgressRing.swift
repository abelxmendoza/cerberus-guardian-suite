import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, lineWidth: CGFloat = 12, size: CGFloat = 120) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.themeDarkGray, lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
    
    private var progressColor: Color {
        if progress >= 0.7 {
            return .themePurple // Base purple for good progress
        } else if progress >= 0.4 {
            return .themePurpleLight // Lighter purple for moderate
        } else {
            return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple for low progress
        }
    }
}

struct ProgressRingWithLabel: View {
    let progress: Double
    let label: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            ProgressRing(progress: progress, size: size)
            
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))")
                    .font(.macGuardianTitle2)
                    .foregroundColor(.themeText)
                Text(label)
                    .font(.macGuardianCaption)
                    .foregroundColor(.themeTextSecondary)
            }
        }
    }
}

