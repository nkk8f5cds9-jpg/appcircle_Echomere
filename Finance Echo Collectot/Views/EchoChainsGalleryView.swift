import SwiftUI
import CoreData

struct EchoChainsGalleryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialEcho.createdAt, ascending: false)],
        animation: .default
    ) private var allEchoes: FetchedResults<FinancialEcho>
    
    @State private var selectedTone: UUID?
    @State private var selectedChain: EchoChain?
    
    var chains: [EchoChain] {
        var chainMap: [UUID: EchoChain] = [:]
        
        for echo in allEchoes {
            var rootEcho = echo
            while let parent = rootEcho.parentEcho {
                rootEcho = parent
            }
            
            guard let rootId = rootEcho.id else { continue }
            
            if chainMap[rootId] == nil {
                chainMap[rootId] = EchoChain(root: rootEcho)
            }
            
            if let echoId = echo.id, echoId != rootId {
                chainMap[rootId]?.addEcho(echo)
            }
        }
        
        return Array(chainMap.values).sorted { $0.totalStrength > $1.totalStrength }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                if chains.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.spacing) {
                            DisclaimerText()
                                .padding(.top, AppTheme.spacing)
                            
                            ForEach(chains) { chain in
                                ChainCard(chain: chain) {
                                    HapticFeedback.selection()
                                    selectedChain = chain
                                }
                                .padding(.horizontal, AppTheme.padding)
                            }
                        }
                        .padding(.bottom, AppTheme.paddingLarge)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Echo Chains")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedChain) { chain in
                ChainDetailView(chain: chain)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            Image(systemName: "link")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.primaryColor.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 8) {
                Text("No chains yet")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text("Create linked echoes to see chains")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.paddingLarge)
        }
        .padding(.vertical, AppTheme.paddingLarge * 2)
    }
}

struct EchoChain: Identifiable {
    let id: UUID
    let root: FinancialEcho
    var echoes: [FinancialEcho] = []
    
    init(root: FinancialEcho) {
        self.id = root.id ?? UUID()
        self.root = root
        self.echoes = [root]
    }
    
    mutating func addEcho(_ echo: FinancialEcho) {
        echoes.append(echo)
    }
    
    var totalStrength: Int {
        echoes.reduce(0) { $0 + Int($1.connectionStrength) }
    }
    
    var length: Int {
        echoes.count
    }
    
    var yearsSpan: Int {
        let dates = echoes.compactMap { $0.pastDate }
        guard let oldest = dates.min(),
              let newest = dates.max() else {
            return 0
        }
        return Calendar.current.dateComponents([.year], from: oldest, to: newest).year ?? 0
    }
}

struct ChainCard: View {
    let chain: EchoChain
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                headerView
                chainVisualization
            }
            .padding(AppTheme.padding)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .top) {
            titleSection
            Spacer()
            strengthSection
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chain.root.title ?? "Untitled Chain")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                Label("\(chain.length)", systemImage: "link")
                Text("•")
                Label("\(chain.yearsSpan) years", systemImage: "calendar")
            }
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)
        }
    }
    
    // MARK: - Strength Section
    private var strengthSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(chain.totalStrength)")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.accentColor)
            
            Text("strength")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
    
    // MARK: - Chain Visualization
    private var chainVisualization: some View {
        HStack(spacing: 8) {
            ForEach(chain.echoes.prefix(8)) { echo in
                echoCircle(for: echo)
            }
            
            if chain.echoes.count > 8 {
                remainingCountBadge
            }
        }
    }
    
    // MARK: - Echo Circle
    private func echoCircle(for echo: FinancialEcho) -> some View {
        let fillColor = echo.isResolved ? AppTheme.sageGreen : AppTheme.primaryColor
        let strokeColor = echo.isResolved ? AppTheme.sageGreen : AppTheme.accentColor
        let shadowColor = (echo.isResolved ? AppTheme.sageGreen : AppTheme.accentColor).opacity(0.3)
        
        return Circle()
            .fill(fillColor)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(strokeColor, lineWidth: 2)
            )
            .shadow(color: shadowColor, radius: 4)
    }
    
    // MARK: - Remaining Count Badge
    private var remainingCountBadge: some View {
        Text("+\(chain.echoes.count - 8)")
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(AppTheme.cardMaterial)
            )
    }
    
    // MARK: - Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
            .fill(AppTheme.cardMaterial)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ChainDetailView: View {
    let chain: EchoChain
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEcho: FinancialEcho?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing) {
                        DisclaimerText()
                            .padding(.top, AppTheme.spacing)
                        
                        ForEach(chain.echoes) { echo in
                            ModernEchoCard(echo: echo) {
                                selectedEcho = echo
                            }
                            .padding(.horizontal, AppTheme.padding)
                        }
                    }
                    .padding(.bottom, AppTheme.paddingLarge)
                }
            }
            .navigationTitle("Chain Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .sheet(item: $selectedEcho) { echo in
                EchoDetailView(echo: echo)
            }
        }
    }
}

#Preview {
    EchoChainsGalleryView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
