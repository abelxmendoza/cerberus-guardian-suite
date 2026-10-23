import SwiftUI

/// Module status indicator component
struct ModuleStatusIndicator: View {
    let moduleName: String
    let isRunning: Bool
    let lastUpdate: Date?
    
    init(moduleName: String, isRunning: Bool, lastUpdate: Date? = nil) {
        self.moduleName = moduleName
        self.isRunning = isRunning
        self.lastUpdate = lastUpdate
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(moduleName)
                    .font(.subheadline.bold())
                    .foregroundColor(.themeText)
                
                HStack(spacing: 4) {
                    Text(isRunning ? "Running" : "Stopped")
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                    
                    if let lastUpdate = lastUpdate {
                        Text("•")
                            .foregroundColor(.themeTextSecondary)
                        Text(formatTime(lastUpdate))
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        isRunning ? .green : Color(red: 0.9, green: 0.1, blue: 0.3)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

