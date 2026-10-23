import SwiftUI

struct PermissionsView: View {
    @State private var fullDiskAccessGranted = false
    @State private var devToolsGranted = false
    @State private var terminalGranted = false
    
    var onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Required Permissions", icon: "lock.shield.fill")
                
                Text("MacGuardian Suite needs the following macOS permissions to function properly:")
                    .font(.macGuardianBody)
                    .foregroundColor(.themeTextSecondary)
                    .padding(.bottom)
                
                // Full Disk Access
                PermissionCard(
                    title: "Full Disk Access",
                    description: "Required to monitor file integrity and detect unauthorized changes",
                    icon: "externaldrive.fill",
                    isGranted: $fullDiskAccessGranted
                )
                
                // Developer Tools
                PermissionCard(
                    title: "Developer Tools",
                    description: "Needed for advanced process monitoring and system analysis",
                    icon: "wrench.and.screwdriver.fill",
                    isGranted: $devToolsGranted
                )
                
                // Terminal Access
                PermissionCard(
                    title: "Terminal Access",
                    description: "Required to execute security scripts and remediation actions",
                    icon: "terminal.fill",
                    isGranted: $terminalGranted
                )
                
                // Instructions
                CardContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Grant Permissions")
                            .font(.macGuardianTitle3)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InstructionStep(number: 1, text: "Click 'Open System Settings' below")
                            InstructionStep(number: 2, text: "Navigate to Privacy & Security")
                            InstructionStep(number: 3, text: "Enable MacGuardian Suite for each permission")
                            InstructionStep(number: 4, text: "Return to this app and click 'Continue'")
                        }
                    }
                }
                
                // Open System Settings button
                Button {
                    openSystemSettings()
                } label: {
                    Label("Open System Settings", systemImage: "gear")
                        .font(.macGuardianSubtitle)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themePurple)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.macGuardianSubtitle)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            allPermissionsGranted ? Color.green.opacity(0.2) : Color.themeDarkGray
                        )
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!allPermissionsGranted)
                .padding(.top)
            }
            .padding(LayoutGuides.paddingLarge)
        }
        .background(Color.themeBlack)
        .onAppear {
            checkPermissions()
        }
    }
    
    private var allPermissionsGranted: Bool {
        fullDiskAccessGranted && devToolsGranted && terminalGranted
    }
    
    private func checkPermissions() {
        // Check actual permissions (simplified - would need proper API calls)
        // For now, simulate checking
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // In production, check actual permission status
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct PermissionCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isGranted: Bool
    
    var body: some View {
        CardContainer {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isGranted ? .green : .orange)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.macGuardianTitle3)
                    Text(description)
                        .font(.macGuardianCaption)
                        .foregroundColor(.themeTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isGranted ? .green : .red)
                    .font(.title3)
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.macGuardianBodyBold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.themePurple)
                .clipShape(Circle())
            
            Text(text)
                .font(.macGuardianBody)
                .foregroundColor(.themeText)
        }
    }
}

