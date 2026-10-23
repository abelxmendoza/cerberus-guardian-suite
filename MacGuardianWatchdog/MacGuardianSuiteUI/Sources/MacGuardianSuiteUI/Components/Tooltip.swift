import SwiftUI

struct Tooltip: View {
    let text: String
    @State private var isVisible = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isVisible {
                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.macGuardianCaption)
                        .foregroundColor(.themeText)
                        .padding(8)
                        .background(Color.themeDarkGray)
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Arrow
                    Triangle()
                        .fill(Color.themeDarkGray)
                        .frame(width: 8, height: 8)
                        .offset(x: -20, y: -4)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onHover { hovering in
            withAnimation {
                isVisible = hovering
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

