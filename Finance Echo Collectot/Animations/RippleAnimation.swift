import SwiftUI

// MARK: - Modern Ripple Effects
struct RippleEffect: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.8
    
    var color: Color = AppTheme.primaryColor
    var duration: Double = 1.2
    
    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .spring(response: 0.8, dampingFraction: 0.6)
                    .repeatForever(autoreverses: false)
                ) {
                    scale = 2.0
                    opacity = 0.0
                }
            }
    }
}

// MARK: - Modern Floating Action Button
struct RippleButton: View {
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.0
    
    let action: () -> Void
    let label: String
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.medium)
            withAnimation(AppTheme.springAnimation) {
                rippleScale = 1.2
                rippleOpacity = 0.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(AppTheme.springAnimation) {
                    rippleScale = 1.0
                    rippleOpacity = 0.0
                }
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor.opacity(rippleOpacity))
                    .frame(width: 80, height: 80)
                    .scaleEffect(rippleScale)
                
                Text(label)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)
            .background(
                Circle()
                    .fill(AppTheme.accentColor)
                    .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Animated Connecting Line
struct ConnectingLine: View {
    let from: CGPoint
    let to: CGPoint
    @State private var pathLength: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .trimmedPath(from: 0, to: pathLength)
        .stroke(
            AppTheme.accentColor.opacity(0.5),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
        .onAppear {
            withAnimation(
                .spring(response: 1.0, dampingFraction: 0.8)
                .delay(0.2)
            ) {
                pathLength = 1.0
            }
        }
    }
}

// MARK: - Modern Glow Effect
struct GlowEffect: ViewModifier {
    let color: Color
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4 * intensity), radius: intensity * 8, x: 0, y: 0)
            .shadow(color: color.opacity(0.2 * intensity), radius: intensity * 16, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color = AppTheme.accentColor, intensity: CGFloat = 1.0) -> some View {
        modifier(GlowEffect(color: color, intensity: intensity))
    }
}
