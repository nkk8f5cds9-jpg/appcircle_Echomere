import SwiftUI

// MARK: - Professional Onboarding View
struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme
    
    let pages = [
        OnboardingPage(
            title: "A quiet space to notice how past money choices echo today",
            description: "Reflect on how financial decisions from your past continue to influence your present thoughts and behaviors.",
            icon: "waveform.path",
            color: AppTheme.primaryColor
        ),
        OnboardingPage(
            title: "Connect moments, see patterns, find freedom in awareness",
            description: "Link past events to current triggers, discover recurring themes, and gain clarity through mindful observation.",
            icon: "link.circle.fill",
            color: AppTheme.accentColor
        ),
        OnboardingPage(
            title: "Private, offline, gentle reflection — no judgment",
            description: "Your personal journal stays completely private on your device. No tracking, no sharing, just you and your insights.",
            icon: "lock.shield.fill",
            color: AppTheme.secondaryColor
        )
    ]
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            VStack {
                Spacer()
                
                if currentPage == pages.count - 1 {
                    beginButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: currentPage) { _ in
            HapticFeedback.selection()
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        Group {
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 2,
                    height: 2,
                    points: [
                        .init(0, 0), .init(1, 0),
                        .init(0, 1), .init(1, 1)
                    ],
                    colors: [
                        AppTheme.backgroundPrimary,
                        AppTheme.backgroundPrimary.opacity(0.95),
                        AppTheme.backgroundPrimary.opacity(0.95),
                        AppTheme.backgroundPrimary
                    ]
                )
            } else {
                LinearGradient(
                    colors: [
                        AppTheme.backgroundPrimary,
                        AppTheme.backgroundPrimary.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // MARK: - Begin Button
    private var beginButton: some View {
        Button(action: {
            HapticFeedback.impact(.medium)
            isComplete = true
        }) {
            HStack(spacing: AppTheme.spacing) {
                Text("Begin Reflection")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.spacing + 4)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: AppTheme.primaryColor.opacity(0.4), radius: 12, x: 0, y: 6)
            )
            .padding(.horizontal, AppTheme.padding)
            .padding(.bottom, AppTheme.paddingLarge)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            Spacer()
            
            // Icon with animation
            iconView
            
            // Content
            contentView
            
            Spacer()
            
            DisclaimerText()
        }
        .padding(.vertical, AppTheme.paddingLarge)
        .onAppear {
            animateOnAppear()
        }
    }
    
    // MARK: - Icon View
    private var iconView: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            page.color.opacity(0.15),
                            page.color.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 140, height: 140)
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [page.color, page.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .symbolEffect(.bounce, value: iconScale)
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: AppTheme.spacing) {
            Text(page.title)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.paddingLarge)
                .offset(y: contentOffset)
                .opacity(iconOpacity)
            
            Text(page.description)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, AppTheme.paddingLarge)
                .offset(y: contentOffset)
                .opacity(iconOpacity)
        }
    }
    
    // MARK: - Animation
    private func animateOnAppear() {
        withAnimation(
            .spring(response: 0.8, dampingFraction: 0.7)
            .delay(0.1)
        ) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        withAnimation(
            .spring(response: 0.8, dampingFraction: 0.8)
            .delay(0.3)
        ) {
            contentOffset = 0
        }
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}
