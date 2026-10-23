import SwiftUI

/// Animation system for MacGuardian Suite
struct AppAnimations {
    // Fade transitions
    static let fadeIn = Animation.easeIn(duration: 0.3)
    static let fadeOut = Animation.easeOut(duration: 0.3)
    
    // Spring animations
    static let springPop = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let springBounce = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    // Hover effects
    static let hoverPulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    
    // Loading animations
    static let loadingRotation = Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
}

/// Animated view modifiers
struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(AppAnimations.fadeIn) {
                    opacity = 1.0
                }
            }
    }
}

struct ScaleOnAppearModifier: ViewModifier {
    @State private var scale: CGFloat = 0.8
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(AppAnimations.springPop) {
                    scale = 1.0
                }
            }
    }
}

struct HoverPulseModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(AppAnimations.springPop, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func fadeIn() -> some View {
        modifier(FadeInModifier())
    }
    
    func scaleOnAppear() -> some View {
        modifier(ScaleOnAppearModifier())
    }
    
    func hoverPulse() -> some View {
        modifier(HoverPulseModifier())
    }
}

