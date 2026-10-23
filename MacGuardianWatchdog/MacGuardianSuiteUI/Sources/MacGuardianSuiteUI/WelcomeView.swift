import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var showPathPicker = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 50
    @State private var contentOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.themeBlack,
                    Color.themeBlack.opacity(0.95),
                    Color.themeDarkGray.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo Section with Animation
                VStack(spacing: 24) {
                    LogoView(size: 200)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: .themePurple.opacity(0.5), radius: 30, x: 0, y: 10)
                        .shadow(color: .themePurple.opacity(0.3), radius: 60, x: 0, y: 20)
                        .overlay(
                            // Animated glow ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .themePurple.opacity(0.6),
                                            .themePurpleLight.opacity(0.3),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 220, height: 220)
                                .blur(radius: 8)
                                .opacity(logoOpacity)
                        )
                    
                    // Welcome Text with Animation
                    VStack(spacing: 16) {
                        Text("Welcome to")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.themeTextSecondary)
                            .opacity(contentOpacity)
                        
                        Text("MacGuardian Suite")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.themePurple, .themePurpleLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(contentOpacity)
                        
                        Text("🛡️ Your comprehensive security toolkit for macOS")
                            .font(.title3)
                            .foregroundColor(.themeTextSecondary)
                            .opacity(contentOpacity)
                        
                        // Omega Technologies branding
                        HStack(spacing: 8) {
                            Text("Powered by")
                                .font(.caption)
                                .foregroundColor(.themeTextSecondary.opacity(0.7))
                            Text("OMEGA TECHNOLOGIES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.themePurple)
                        }
                        .padding(.top, 8)
                        .opacity(contentOpacity)
                    }
                    .offset(y: contentOffset)
                }
            
                
                // Feature Cards with Animation
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "1.circle.fill",
                        title: "Set Repository Path",
                        description: "Select your MacGuardian project folder to get started"
                    )
                    
                    FeatureRow(
                        icon: "2.circle.fill",
                        title: "Choose a Module",
                        description: "Browse security tools from the sidebar"
                    )
                    
                    FeatureRow(
                        icon: "3.circle.fill",
                        title: "Run & Monitor",
                        description: "Execute scripts and watch live output in real-time"
                    )
                }
                .padding(.horizontal, 40)
                .offset(y: contentOffset)
                .opacity(contentOpacity)
                
                // Repository Path Section with Animation
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.themePurple)
                                .font(.title3)
                            Text("Repository Path")
                                .font(.headline)
                                .foregroundColor(.themeText)
                        }
                        
                        HStack(spacing: 12) {
                            TextField("Path to MacGuardian project", text: $workspace.repositoryPath)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                            
                            Button {
                                showPathPicker = true
                            } label: {
                                Label("Browse", systemImage: "folder.badge.plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.themePurple)
                        }
                        
                        let validation = workspace.validateRepositoryPath()
                        if !validation.isValid {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(validation.message)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(validation.message)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.themeDarkGray)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.themePurple.opacity(0.5), .themePurpleDark.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .frame(maxWidth: 700)
                    
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                workspace.hasSeenWelcome = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text("Get Started")
                                    .font(.headline)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                            }
                            .frame(maxWidth: 300)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.themePurple)
                        .controlSize(.large)
                        .disabled(!workspace.validateRepositoryPath().isValid)
                        .shadow(color: .themePurple.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        // Skip button - always enabled
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                workspace.hasSeenWelcome = true
                            }
                        } label: {
                            Text("Skip Setup")
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("Skip welcome screen and proceed to main app")
                    }
                }
                .offset(y: contentOffset)
                .opacity(contentOpacity)
                
                Spacer()
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Animate logo entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Animate content entrance with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    contentOffset = 0
                    contentOpacity = 1.0
                }
            }
        }
        .fileImporter(
            isPresented: $showPathPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                workspace.repositoryPath = url.path
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.themePurple.opacity(0.2), .themePurpleDark.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.themePurple, .themePurpleLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.themeText)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

