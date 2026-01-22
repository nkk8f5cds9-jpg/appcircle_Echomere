import SwiftUI

// MARK: - Professional Theme System with Dark Mode Support
struct AppTheme {
    // MARK: - Adaptive Color Palette (Light/Dark Mode)
    static var primaryColor: Color {
        Color(light: "0A4D5E", dark: "5DB4C7")
    }
    
    static var accentColor: Color {
        Color(light: "D98C3A", dark: "F5A742")
    }
    
    static var secondaryColor: Color {
        Color(light: "9CAF88", dark: "7A9A6A")
    }
    
    static var backgroundPrimary: Color {
        Color(light: "FDFBF7", dark: "1C1C1E")
    }
    
    static var backgroundSecondary: Color {
        Color(light: "FFFFFF", dark: "2C2C2E")
    }
    
    static var surfaceColor: Color {
        Color(light: "F5F5F7", dark: "3A3A3C")
    }
    
    static var textPrimary: Color {
        Color.primary
    }
    
    static var textSecondary: Color {
        Color.secondary
    }
    
    // Legacy colors for backward compatibility
    static var deepTeal: Color { primaryColor }
    static var warmAmber: Color { accentColor }
    static var softSilver: Color { surfaceColor }
    static var backgroundIvory: Color { backgroundPrimary }
    static var sageGreen: Color { secondaryColor }
    
    // MARK: - Typography System
    static let serifFont = Font.system(.title2, design: .serif).weight(.medium)
    static let serifFontLarge = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let serifFontSmall = Font.system(.body, design: .serif)
    static let interfaceFont = Font.system(.body, design: .rounded)
    
    // MARK: - Spacing System
    static let cornerRadius: CGFloat = 20
    static let cornerRadiusLarge: CGFloat = 28
    static let padding: CGFloat = 20
    static let paddingLarge: CGFloat = 32
    static let spacing: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    
    // MARK: - Modern Animations
    static let springAnimation = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let smoothAnimation = Animation.easeInOut(duration: 0.3)
    static let slowAnimation = Animation.easeInOut(duration: 0.6)
    static let verySlowAnimation = Animation.easeInOut(duration: 1.2)
    
    // MARK: - Material Effects
    static var cardMaterial: Material {
        .ultraThinMaterial
    }
    
    static var backgroundMaterial: Material {
        .regularMaterial
    }
}

// MARK: - Color Extension for Adaptive Colors
extension Color {
    init(light: String, dark: String) {
        self.init(
            UIColor { traitCollection in
                let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
                return UIColor(hex: hex)
            }
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Legacy Color Extension (for backward compatibility)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Professional Disclaimer Component
struct DisclaimerText: View {
    var body: some View {
        Text("This is a personal journaling tool for tracking financial decision patterns. Not financial, medical, or therapeutic advice.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, AppTheme.spacing / 2)
    }
}

// MARK: - Haptic Feedback Helper
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
