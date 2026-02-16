import SwiftUI
import CoreData

// MARK: - Professional Dashboard View
struct MainDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialEcho.createdAt, ascending: false)],
        animation: .default
    ) private var echoes: FetchedResults<FinancialEcho>
    
    @State private var headerOffset: CGFloat = 0
    @State private var showAllEchoes = false
    @State private var navigationPath = NavigationPath()
    
    var echoCount: Int {
        echoes.count
    }
    
    var lastEchoDaysAgo: Int? {
        guard let lastEcho = echoes.first,
              let createdAt = lastEcho.createdAt else { return nil }
        let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day
        return days
    }
    
    var longestChain: Int {
        var maxChain = 0
        for echo in echoes {
            var chainLength = 1
            var current: FinancialEcho? = echo
            while let parent = current?.parentEcho {
                chainLength += 1
                current = parent
            }
            maxChain = max(maxChain, chainLength)
        }
        return maxChain
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Modern gradient background
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacingLarge) {
                        headerSection
                        
                        if !echoes.isEmpty {
                            chainVisualizationSection
                            statsSection
                            recentEchoesSection
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
                
                // Modern floating action button
                floatingActionButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Echoes")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .newEcho:
                    EchoFormView(echo: nil)
                        .navigationBarBackButtonHidden(false)
                case .editEcho(let echoId):
                    if let echo = echoes.first(where: { $0.id == echoId }) {
                        EchoFormView(echo: echo)
                    } else {
                        ContentUnavailableView {
                            Label("Echo not found", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text("The echo you're looking for doesn't exist.")
                        } actions: {
                            Button("Go Back") {
                                navigationPath.removeLast()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                case .echoDetail(let echoId):
                    if let echo = echoes.first(where: { $0.id == echoId }) {
                        EchoDetailView(echo: echo)
                    } else {
                        ContentUnavailableView {
                            Label("Echo not found", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text("The echo you're looking for doesn't exist.")
                        } actions: {
                            Button("Go Back") {
                                navigationPath.removeLast()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                case .allEchoes:
                    AllEchoesView()
                }
            }
        }
    }
    
    // MARK: - Navigation Destination
    enum NavigationDestination: Hashable {
        case newEcho
        case editEcho(UUID)
        case echoDetail(UUID)
        case allEchoes
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        Group {
            if #available(iOS 18.0, *) {
                // MeshGradient for iOS 18+
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
                // Fallback gradient for iOS 17
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(echoCount)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.primaryColor)
                        .contentTransition(.numericText())
                    
                    Text("financial echoes")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, AppTheme.spacing)
            
            DisclaimerText()
        }
    }
    
    // MARK: - Chain Visualization
    private var chainVisualizationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Echo Chain")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.padding)
            
            EchoChainVisualization(echoes: Array(echoes))
                .frame(height: 180)
                .padding(.horizontal, AppTheme.padding)
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: AppTheme.spacing) {
            if let days = lastEchoDaysAgo {
                ModernStatCard(
                    title: "Last echo",
                    value: "\(days)",
                    subtitle: days == 1 ? "day ago" : "days ago",
                    icon: "clock.fill",
                    color: AppTheme.accentColor
                )
            }
            
            ModernStatCard(
                title: "Longest chain",
                value: "\(longestChain)",
                subtitle: longestChain == 1 ? "year" : "years",
                icon: "link.circle.fill",
                color: AppTheme.secondaryColor
            )
        }
        .padding(.horizontal, AppTheme.padding)
    }
    
    // MARK: - Recent Echoes
    private var recentEchoesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Text("Recent Echoes")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Spacer()
                
                if echoes.count > 5 {
                    Button(action: {
                        showAllEchoes = true
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.accentColor)
                    }
                }
            }
            .padding(.horizontal, AppTheme.padding)
            
            ForEach(Array(echoes.prefix(5))) { echo in
                ModernEchoCard(echo: echo) {
                    HapticFeedback.impact(.light)
                    if let echoId = echo.id {
                        navigationPath.append(NavigationDestination.echoDetail(echoId))
                    }
                }
                .padding(.horizontal, AppTheme.padding)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            Image(systemName: "waveform.path")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.primaryColor.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 8) {
                Text("No echoes yet")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text("Start by creating your first financial echo")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.paddingLarge)
        }
        .padding(.vertical, AppTheme.paddingLarge * 2)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    HapticFeedback.impact(.medium)
                    navigationPath.append(NavigationDestination.newEcho)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(AppTheme.accentColor)
                                .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                }
                .buttonStyle(.plain)
                .padding(.trailing, AppTheme.padding)
                .padding(.bottom, AppTheme.padding)
            }
        }
    }
}

// MARK: - Modern Stat Card
struct ModernStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, value: value)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.numericText())
                    
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Modern Echo Card
struct ModernEchoCard: View {
    let echo: FinancialEcho
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(echo.title ?? "Untitled Echo")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    if let createdAt = echo.createdAt {
                        Text(createdAt, style: .relative)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                EchoStrengthBadge(strength: Int(echo.connectionStrength))
            }
            .padding(AppTheme.padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Echo: \(echo.title ?? "Untitled Echo"). Connection strength: \(echo.connectionStrength) out of 10")
            .accessibilityHint("Tap to view echo details")
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Echo Strength Badge
struct EchoStrengthBadge: View {
    let strength: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(strengthColor.opacity(0.15))
                .frame(width: 48, height: 48)
            
            Text("\(strength)")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(strengthColor)
        }
        .overlay(
            Circle()
                .stroke(strengthColor.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    var strengthColor: Color {
        if strength >= 7 {
            return AppTheme.accentColor
        } else if strength >= 4 {
            return AppTheme.primaryColor
        } else {
            return AppTheme.textSecondary
        }
    }
}

// MARK: - Chain Visualization
struct EchoChainVisualization: View {
    let echoes: [FinancialEcho]
    @State private var animatedNodes: Set<UUID> = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Connecting lines with animation
                ForEach(echoes.prefix(10)) { echo in
                    if let parent = echo.parentEcho,
                       let parentId = parent.id,
                       let echoId = echo.id,
                       let parentIndex = echoes.firstIndex(where: { $0.id == parentId }) {
                        if let echoIndex = echoes.firstIndex(where: { $0.id == echoId }) {
                            let fromX = CGFloat(parentIndex) * (geometry.size.width / CGFloat(min(echoes.count, 10))) + 20
                            let toX = CGFloat(echoIndex) * (geometry.size.width / CGFloat(min(echoes.count, 10))) + 20
                            
                            ConnectingLine(
                                from: CGPoint(x: fromX, y: 90),
                                to: CGPoint(x: toX, y: 90)
                            )
                        }
                    }
                }
                
                // Animated nodes
                HStack(spacing: (geometry.size.width - 200) / CGFloat(min(echoes.count, 10) - 1)) {
                    ForEach(echoes.prefix(10)) { echo in
                        echoNode(for: echo)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardMaterial)
        )
    }
    
    private func echoNode(for echo: FinancialEcho) -> some View {
        Circle()
            .fill(echo.isResolved ? AppTheme.secondaryColor : AppTheme.primaryColor)
            .frame(width: 16, height: 16)
            .scaleEffect(echo.id.map { animatedNodes.contains($0) } ?? false ? 1.3 : 1.0)
            .animation(AppTheme.springAnimation, value: animatedNodes.contains(echo.id ?? UUID()))
            .onAppear {
                if let echoId = echo.id {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.5)) {
                        animatedNodes.insert(echoId)
                    }
                }
            }
    }
}

#Preview {
    MainDashboardView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
