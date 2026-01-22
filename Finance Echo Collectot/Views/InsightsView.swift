import SwiftUI
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialEcho.createdAt, ascending: true)],
        animation: .default
    ) private var echoes: FetchedResults<FinancialEcho>
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundIvory
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        DisclaimerText()
                            .padding(.top, 20)
                        
                        // Echo Frequency Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Echo Frequency Over Time")
                                .font(AppTheme.serifFontSmall)
                                .foregroundColor(AppTheme.deepTeal)
                            
                            EchoFrequencyChart(echoes: Array(echoes))
                                .frame(height: 200)
                                .padding()
                                .background(AppTheme.softSilver.opacity(0.2))
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        // Statistics
                        VStack(spacing: 16) {
                            Text("Insights")
                                .font(AppTheme.serifFontSmall)
                                .foregroundColor(AppTheme.deepTeal)
                            
                            if let mostEchoed = mostEchoedDecisionType {
                                StatisticCard(
                                    title: "Most Echoed Decision Type",
                                    value: mostEchoed,
                                    icon: "chart.bar.fill"
                                )
                            }
                            
                            if let longestUnresolved = longestUnresolvedEcho {
                                StatisticCard(
                                    title: "Longest Unresolved Echo",
                                    value: "\(longestUnresolved.title ?? "Untitled") (\(yearsAgo(longestUnresolved.pastDate ?? Date())) years)",
                                    icon: "clock.fill"
                                )
                            }
                            
                            StatisticCard(
                                title: "Average Connection Strength",
                                value: String(format: "%.1f", averageStrength),
                                icon: "gauge.high"
                            )
                            
                            StatisticCard(
                                title: "Resolution Rate",
                                value: String(format: "%.0f%%", resolutionRate),
                                icon: "checkmark.circle.fill"
                            )
                            
                            StatisticCard(
                                title: "Strength Trend",
                                value: strengthTrend,
                                icon: "chart.line.uptrend.xyaxis"
                            )
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        // Word Cloud (simplified as tag cloud)
                        if !recurringThemes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recurring Themes")
                                    .font(AppTheme.serifFontSmall)
                                    .foregroundColor(AppTheme.deepTeal)
                                
                                ThemeCloud(themes: recurringThemes)
                                    .padding()
                                    .background(AppTheme.softSilver.opacity(0.2))
                                    .cornerRadius(AppTheme.cornerRadius)
                            }
                            .padding(.horizontal, AppTheme.padding)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Insights & Patterns")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var mostEchoedDecisionType: String? {
        // Analyze common patterns in past situations
        var patternCount: [String: Int] = [:]
        let commonPatterns = ["spending", "saving", "investment", "debt", "budget", "purchase", "loan", "credit"]
        
        for echo in echoes {
            let text = ((echo.pastSituation ?? "") + " " + (echo.title ?? "")).lowercased()
            for pattern in commonPatterns {
                if text.contains(pattern) {
                    patternCount[pattern, default: 0] += 1
                }
            }
        }
        
        if let mostCommon = patternCount.max(by: { $0.value < $1.value }) {
            return mostCommon.key.capitalized + " (\(mostCommon.value) times)"
        }
        
        return nil
    }
    
    var resolutionRate: Double {
        guard !echoes.isEmpty else { return 0 }
        let resolvedCount = echoes.filter { $0.isResolved }.count
        return Double(resolvedCount) / Double(echoes.count) * 100
    }
    
    var strengthTrend: String {
        guard echoes.count >= 2 else { return "Insufficient data" }
        let recent = Array(echoes.suffix(5))
        let older = Array(echoes.prefix(5))
        
        let recentAvg = recent.reduce(0) { $0 + Double($1.connectionStrength) } / Double(recent.count)
        let olderAvg = older.reduce(0) { $0 + Double($1.connectionStrength) } / Double(older.count)
        
        if recentAvg > olderAvg {
            return "Increasing"
        } else if recentAvg < olderAvg {
            return "Decreasing"
        } else {
            return "Stable"
        }
    }
    
    var longestUnresolvedEcho: FinancialEcho? {
        echoes.filter { !$0.isResolved && $0.pastDate != nil }
            .min { yearsAgo($0.pastDate ?? Date()) < yearsAgo($1.pastDate ?? Date()) }
    }
    
    var averageStrength: Double {
        guard !echoes.isEmpty else { return 0 }
        let sum = echoes.reduce(0) { $0 + Double($1.connectionStrength) }
        return sum / Double(echoes.count)
    }
    
    var recurringThemes: [(String, Int)] {
        var themes: [String: Int] = [:]
        let stopWords = Set(["this", "that", "with", "from", "have", "been", "will", "would", "could", "should", "about", "their", "there", "these", "those"])
        
        for echo in echoes {
            let text = (echo.title ?? "") + " " + (echo.pastSituation ?? "") + " " + (echo.currentTrigger ?? "")
            let words = text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 4 && !stopWords.contains($0) }
            
            for word in words {
                themes[word, default: 0] += 1
            }
        }
        return Array(themes)
            .filter { $0.value > 1 }
            .sorted { $0.value > $1.value }
            .prefix(15)
            .map { ($0.key.capitalized, $0.value) }
    }
    
    func yearsAgo(_ date: Date) -> Int {
        Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    }
}

struct EchoFrequencyChart: View {
    let echoes: [FinancialEcho]
    
    var data: [(String, Int)] {
        var frequency: [String: Int] = [:]
        for echo in echoes {
            if let createdAt = echo.createdAt {
                let year = Calendar.current.component(.year, from: createdAt)
                frequency[String(year), default: 0] += 1
            }
        }
        return frequency.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        // Custom bar chart implementation
        VStack(alignment: .leading, spacing: 8) {
            ForEach(data, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .font(.system(size: 12))
                        .frame(width: 50)
                    
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.warmAmber)
                            .frame(width: geometry.size.width * CGFloat(item.1) / CGFloat(maxCount), height: 20)
                    }
                    .frame(height: 20)
                    
                    Text("\(item.1)")
                        .font(.system(size: 12))
                        .frame(width: 30)
                }
            }
        }
    }
    
    var maxCount: Int {
        data.map { $0.1 }.max() ?? 1
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.warmAmber)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(AppTheme.serifFontSmall)
                    .foregroundColor(AppTheme.deepTeal)
            }
            
            Spacer()
        }
        .padding(AppTheme.padding)
        .background(AppTheme.softSilver.opacity(0.2))
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct ThemeCloud: View {
    let themes: [(String, Int)]
    
    var body: some View {
        FlowLayout(spacing: 12) {
            ForEach(themes, id: \.0) { theme in
                Text(theme.0)
                    .font(.system(size: CGFloat(12 + theme.1), weight: .medium))
                    .foregroundColor(AppTheme.deepTeal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.warmAmber.opacity(0.2))
                    .cornerRadius(16)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    InsightsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
