import SwiftUI
import CoreData

// MARK: - Professional Echo Detail View
struct EchoDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var echo: FinancialEcho
    @State private var showFollowUp = false
    @State private var showResolveConfirmation = false
    @State private var gaugeProgress: CGFloat = 0
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        ZStack {
            // Modern background
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: AppTheme.spacingLarge) {
                    headerSection
                    comparisonSection
                    strengthGaugeSection
                    insightSection
                    photoSection
                    tonesSection
                    actionButtonsSection
                }
                .padding(.bottom, AppTheme.paddingLarge)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Echo Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    HapticFeedback.selection()
                    dismiss()
                }
                .foregroundStyle(AppTheme.accentColor)
            }
        }
        .navigationDestination(for: EditDestination.self) { destination in
            Group {
                switch destination {
                case .editEcho:
                    EchoFormView(echo: echo)
                }
            }
        }
        .sheet(isPresented: $showFollowUp) {
            QuickFollowUpView(parentEcho: echo)
        }
        .alert("Mark as Resolved?", isPresented: $showResolveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Resolve") {
                HapticFeedback.notification(.success)
                echo.isResolved = true
                echo.resolvedDate = Date()
                do {
                    try viewContext.save()
                    viewContext.processPendingChanges()
                } catch {
                    print("Error saving: \(error)")
                    viewContext.rollback()
                }
            }
        } message: {
            Text("This will mark this echo as resolved. You can still edit it later.")
        }
        .onAppear {
            withAnimation(AppTheme.springAnimation.delay(0.2)) {
                gaugeProgress = CGFloat(echo.connectionStrength) / 10.0
            }
        }
    }
    
    enum EditDestination: Hashable {
        case editEcho
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
                        AppTheme.backgroundPrimary.opacity(0.8),
                        AppTheme.backgroundPrimary.opacity(0.9),
                        AppTheme.backgroundPrimary
                    ]
                )
            } else {
                LinearGradient(
                    colors: [
                        AppTheme.backgroundPrimary,
                        AppTheme.backgroundPrimary.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppTheme.spacing) {
            DisclaimerText()
                .padding(.top, AppTheme.spacing)
            
            VStack(spacing: AppTheme.spacing) {
                Text(echo.title ?? "Untitled Echo")
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.padding)
                
                timelineIndicator
            }
        }
    }
    
    // MARK: - Timeline Indicator
    private var timelineIndicator: some View {
        HStack(spacing: AppTheme.spacing) {
            dateCard(
                label: "Past",
                date: echo.pastDate,
                color: AppTheme.primaryColor
            )
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.accentColor)
                .symbolEffect(.pulse, options: .repeating)
            
            dateCard(
                label: "Present",
                date: echo.createdAt,
                color: AppTheme.accentColor
            )
        }
        .padding(.horizontal, AppTheme.padding)
    }
    
    private func dateCard(label: String, date: Date?, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if let date = date {
                Text(date, style: .date)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(color)
            } else {
                Text("—")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacing)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardMaterial)
        )
    }
    
    // MARK: - Comparison Section
    private var comparisonSection: some View {
        VStack(spacing: AppTheme.spacing) {
            HStack {
                Text("Comparison")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppTheme.padding)
            
            HStack(alignment: .top, spacing: AppTheme.spacing) {
                comparisonCard(
                    title: "Past Situation",
                    content: echo.pastSituation ?? "",
                    icon: "clock.arrow.circlepath"
                )
                
                comparisonCard(
                    title: "Current Trigger",
                    content: echo.currentTrigger ?? "",
                    icon: "sparkles"
                )
            }
            .padding(.horizontal, AppTheme.padding)
        }
    }
    
    private func comparisonCard(title: String, content: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.accentColor)
                
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            
            Text(content)
                .font(.system(.body, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Strength Gauge
    private var strengthGaugeSection: some View {
        VStack(spacing: AppTheme.spacing) {
            Text("Connection Strength")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        AppTheme.surfaceColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: gaugeProgress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                AppTheme.primaryColor,
                                AppTheme.accentColor,
                                AppTheme.accentColor.opacity(0.8)
                            ],
                            center: .center,
                            angle: .degrees(-90)
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                
                // Value
                VStack(spacing: 4) {
                    Text("\(echo.connectionStrength)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.numericText())
                    
                    Text("of 10")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, AppTheme.spacing)
    }
    
    // MARK: - Insight Section
    @ViewBuilder
    private var insightSection: some View {
        if let insight = echo.insight, !insight.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.accentColor)
                    
                    Text("Insight")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, AppTheme.padding)
                
                Text(insight)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(AppTheme.padding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .fill(AppTheme.cardMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, AppTheme.padding)
            }
        }
    }
    
    // MARK: - Photo Section
    @ViewBuilder
    private var photoSection: some View {
        if let photoData = echo.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                .padding(.horizontal, AppTheme.padding)
        }
    }
    
    // MARK: - Tones Section
    @ViewBuilder
    private var tonesSection: some View {
        if let tonesArray = echo.value(forKey: "emotionalTones") as? [String], !tonesArray.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.accentColor)
                    
                    Text("Emotional Tones")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, AppTheme.padding)
                
                let toneIds = tonesArray.compactMap { UUID(uuidString: $0) }
                let tones = fetchTones(ids: toneIds)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacing) {
                        ForEach(tones) { tone in
                            ModernToneChip(tone: tone, isSelected: true)
                        }
                    }
                    .padding(.horizontal, AppTheme.padding)
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.spacing) {
            ModernActionButton(
                title: "Edit",
                icon: "pencil",
                style: .primary,
                action: {
                    HapticFeedback.impact(.medium)
                    navigationPath.append(EditDestination.editEcho)
                }
            )
            
            ModernActionButton(
                title: "Add Follow-up Echo",
                icon: "plus.circle",
                style: .secondary,
                action: {
                    HapticFeedback.impact(.light)
                    showFollowUp = true
                }
            )
            
            if !echo.isResolved {
                ModernActionButton(
                    title: "Mark as Resolved",
                    icon: "checkmark.circle",
                    style: .success,
                    action: {
                        HapticFeedback.impact(.medium)
                        showResolveConfirmation = true
                    }
                )
            } else {
                resolvedBadge
            }
        }
        .padding(.horizontal, AppTheme.padding)
    }
    
    private var resolvedBadge: some View {
        HStack(spacing: AppTheme.spacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryColor)
                .symbolEffect(.bounce, value: echo.isResolved)
            
            if let resolvedDate = echo.resolvedDate {
                Text("Resolved on \(resolvedDate, style: .date)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.secondaryColor.opacity(0.15))
        )
    }
    
    private func fetchTones(ids: [UUID]) -> [EmotionalTone] {
        let request = EmotionalTone.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)
        return (try? viewContext.fetch(request)) ?? []
    }
}

// MARK: - Modern Action Button
struct ModernActionButton: View {
    enum ButtonStyle {
        case primary, secondary, success
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppTheme.primaryColor
            case .secondary: return AppTheme.surfaceColor
            case .success: return AppTheme.secondaryColor.opacity(0.2)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return AppTheme.textPrimary
            case .success: return AppTheme.secondaryColor
            }
        }
    }
    
    let title: String
    let icon: String
    let style: ButtonStyle
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.spacing)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(style.backgroundColor)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Tone Chip
struct ModernToneChip: View {
    let tone: EmotionalTone
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            if let iconName = tone.iconName {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .medium))
            }
            
            Text(tone.name ?? "Unknown")
                .font(.system(.caption, design: .rounded, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(toneColor.opacity(isSelected ? 0.2 : 0.1))
        )
        .foregroundStyle(toneColor)
        .overlay(
            Capsule()
                .stroke(toneColor.opacity(isSelected ? 0.5 : 0.2), lineWidth: 1.5)
        )
    }
    
    var toneColor: Color {
        if let hex = tone.colorHex {
            return Color(hex: hex)
        }
        return AppTheme.primaryColor
    }
}

#Preview {
    let context = CoreDataStack.shared.viewContext
    let echo = FinancialEcho(context: context)
    echo.id = UUID()
    echo.title = "Sample Echo"
    echo.pastDate = Date()
    echo.pastSituation = "Past situation"
    echo.currentTrigger = "Current trigger"
    echo.connectionStrength = 7
    echo.createdAt = Date()
    
    return EchoDetailView(echo: echo)
        .environment(\.managedObjectContext, context)
}
