import SwiftUI

struct SectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(title: String, icon: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.themePurple)
                    .font(.title3)
            }
            
            Text(title)
                .font(.macGuardianTitle3)
                .foregroundColor(.themeText)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .tint(.themePurple)
            }
        }
        .padding(.vertical, LayoutGuides.paddingSmall)
    }
}

