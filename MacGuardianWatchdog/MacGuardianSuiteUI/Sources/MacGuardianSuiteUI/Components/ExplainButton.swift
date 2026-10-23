import SwiftUI

struct ExplainButton: View {
    let title: String
    let explanation: String
    @State private var showExplanation = false
    
    var body: some View {
        Button {
            showExplanation = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.themePurple)
                .font(.macGuardianBody)
        }
        .buttonStyle(.plain)
        .help("Explain this feature")
        .sheet(isPresented: $showExplanation) {
            ExplanationView(title: title, explanation: explanation)
        }
    }
}

struct ExplanationView: View {
    let title: String
    let explanation: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(explanation)
                        .font(.macGuardianBody)
                        .foregroundColor(.themeText)
                        .lineSpacing(4)
                }
                .padding(LayoutGuides.paddingLarge)
            }
            .background(Color.themeBlack)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

