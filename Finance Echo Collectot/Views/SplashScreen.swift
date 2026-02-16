import SwiftUI

// MARK: - Professional Splash Screen with Advanced Animations
struct SplashScreen: View {
    @State private var coinY: CGFloat = -100
    @State private var coinRotation: Double = 0
    @State private var rippleScale: CGFloat = 0.0
    @State private var rippleOpacity: Double = 0.0
    @State private var waveOffset: CGFloat = 0
    @State private var appNameOpacity: Double = 0.0
    @State private var appNameScale: CGFloat = 0.8
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Modern gradient background
            backgroundGradient
                .ignoresSafeArea()
            
            // Subtle water texture
            WaterTexture()
                .opacity(0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                // Coin drop animation with rotation
                coinAnimation
                
                // Timeline wave
                timelineWave
                
                // App name with elegant animation
                appName
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        Group {
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                        .init(0, 1), .init(0.5, 1), .init(1, 1)
                    ],
                    colors: [
                        AppTheme.backgroundPrimary,
                        AppTheme.backgroundPrimary.opacity(0.95),
                        AppTheme.backgroundPrimary,
                        AppTheme.backgroundPrimary.opacity(0.9),
                        AppTheme.primaryColor.opacity(0.05),
                        AppTheme.backgroundPrimary.opacity(0.9),
                        AppTheme.backgroundPrimary,
                        AppTheme.backgroundPrimary.opacity(0.95),
                        AppTheme.backgroundPrimary
                    ]
                )
            } else {
                LinearGradient(
                    colors: [
                        AppTheme.backgroundPrimary,
                        AppTheme.backgroundPrimary.opacity(0.98),
                        AppTheme.backgroundPrimary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // MARK: - Coin Animation
    private var coinAnimation: some View {
        ZStack {
            // Animated ripples
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        AppTheme.primaryColor.opacity(0.2),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .offset(y: coinY)
            }
            
            // Coin with gradient and shadow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.accentColor,
                            AppTheme.accentColor.opacity(0.8),
                            Color(hex: "B87333")
                        ],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 48, height: 48)
                .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .offset(y: coinY)
                .rotationEffect(.degrees(coinRotation))
        }
    }
    
    // MARK: - Timeline Wave
    private var timelineWave: some View {
        TimelineWave(offset: waveOffset)
            .frame(height: 70)
            .padding(.horizontal, 50)
            .opacity(rippleOpacity)
    }
    
    // MARK: - App Name
    private var appName: some View {
        Text("Financial Echo Collector")
            .font(.system(.largeTitle, design: .serif, weight: .semibold))
            .foregroundStyle(
                LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(appNameOpacity)
            .scaleEffect(appNameScale)
    }
    
    // MARK: - Animation Sequence
    private func startAnimations() {
        // Coin drop with rotation
        withAnimation(
            .spring(response: 0.8, dampingFraction: 0.7)
        ) {
            coinY = 0
            coinRotation = 360
        }
        
        // Ripples
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(
                .spring(response: 1.2, dampingFraction: 0.6)
            ) {
                rippleScale = 3.5
                rippleOpacity = 0.5
            }
        }
        
        // Wave animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(
                .linear(duration: 2.0)
                .repeatForever(autoreverses: false)
            ) {
                waveOffset = 360
            }
        }
        
        // App name fade in with scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(
                .spring(response: 0.8, dampingFraction: 0.7)
            ) {
                appNameOpacity = 1.0
                appNameScale = 1.0
            }
        }
    }
}

// MARK: - Water Texture Background
struct WaterTexture: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let waveLength = width / 4
                
                for i in 0..<Int(height / 25) {
                    let y = CGFloat(i) * 25
                    path.move(to: CGPoint(x: 0, y: y))
                    
                    for x in stride(from: 0, through: width, by: 6) {
                        let wave = sin((x / waveLength) * .pi * 2) * 4
                        path.addLine(to: CGPoint(x: x, y: y + wave))
                    }
                }
            }
            .stroke(AppTheme.primaryColor.opacity(0.08), lineWidth: 0.5)
        }
    }
}

// MARK: - Timeline Wave
struct TimelineWave: View {
    let offset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midY = height / 2
                
                path.move(to: CGPoint(x: 0, y: midY))
                
                for x in stride(from: 0, through: width, by: 2) {
                    let wave = sin((x / 60 + offset / 60) * .pi) * 18
                    path.addLine(to: CGPoint(x: x, y: midY + wave))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [
                        AppTheme.primaryColor,
                        AppTheme.accentColor,
                        AppTheme.primaryColor
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
        }
    }
}


