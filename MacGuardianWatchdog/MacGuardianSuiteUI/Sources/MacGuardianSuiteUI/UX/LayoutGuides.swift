import SwiftUI

/// Layout constants and guides for consistent spacing
struct LayoutGuides {
    // Padding
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32
    
    // Card spacing
    static let cardSpacing: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 20
    
    // Section spacing
    static let sectionSpacing: CGFloat = 24
    static let sectionHeaderHeight: CGFloat = 40
    
    // Scroll behavior
    static let scrollPadding: CGFloat = 16
}

/// Standard card container
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(LayoutGuides.cardPadding)
            .background(Color.themeDarkGray)
            .cornerRadius(LayoutGuides.cardCornerRadius)
    }
}

/// Standard section container
struct SectionContainer<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LayoutGuides.cardSpacing) {
            if let title = title {
                SectionHeader(title: title)
            }
            content
        }
        .padding(LayoutGuides.paddingLarge)
    }
}

