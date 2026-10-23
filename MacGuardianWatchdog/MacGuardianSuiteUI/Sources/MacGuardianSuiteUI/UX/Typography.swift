import SwiftUI

/// Typography system for MacGuardian Suite
extension Font {
    // Title fonts (futuristic, bold)
    static let macGuardianTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let macGuardianTitle2 = Font.system(size: 24, weight: .bold, design: .rounded)
    static let macGuardianTitle3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Subtitle fonts
    static let macGuardianSubtitle = Font.system(size: 18, weight: .medium, design: .default)
    static let macGuardianSubtitle2 = Font.system(size: 16, weight: .medium, design: .default)
    
    // Body fonts
    static let macGuardianBody = Font.system(size: 14, weight: .regular, design: .default)
    static let macGuardianBodyBold = Font.system(size: 14, weight: .semibold, design: .default)
    static let macGuardianCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let macGuardianCaptionBold = Font.system(size: 12, weight: .semibold, design: .default)
}

/// Typography helper views
struct TitleText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.macGuardianTitle)
            .foregroundColor(.themeText)
    }
}

struct SubtitleText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.macGuardianSubtitle)
            .foregroundColor(.themeTextSecondary)
    }
}

struct BodyText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.macGuardianBody)
            .foregroundColor(.themeText)
    }
}

