import SwiftUI
import CoreData

// MARK: - All Echoes View with Search, Sort, and Filters
struct AllEchoesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialEcho.createdAt, ascending: false)],
        animation: .default
    ) private var allEchoes: FetchedResults<FinancialEcho>
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateDescending
    @State private var filterOption: FilterOption = .all
    @State private var selectedEcho: FinancialEcho?
    @State private var showSortSheet = false
    @State private var showFilterSheet = false
    
    enum SortOption: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case strengthDescending = "Strongest First"
        case strengthAscending = "Weakest First"
        case titleAscending = "Title A-Z"
        case titleDescending = "Title Z-A"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case resolved = "Resolved"
        case unresolved = "Unresolved"
        case hasParent = "Linked"
        case noParent = "Standalone"
    }
    
    var filteredAndSortedEchoes: [FinancialEcho] {
        var result = Array(allEchoes)
        
        // Optimized search: Use contains for better performance on large datasets
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            // For large datasets, this is more efficient than multiple contains checks
            result = result.filter { echo in
                let searchableText = [
                    echo.title ?? "",
                    echo.pastSituation ?? "",
                    echo.currentTrigger ?? "",
                    echo.insight ?? ""
                ].joined(separator: " ").lowercased()
                return searchableText.contains(searchLower)
            }
        }
        
        // Apply status filter
        switch filterOption {
        case .all:
            break
        case .resolved:
            result = result.filter { $0.isResolved }
        case .unresolved:
            result = result.filter { !$0.isResolved }
        case .hasParent:
            result = result.filter { $0.parentEcho != nil }
        case .noParent:
            result = result.filter { $0.parentEcho == nil }
        }
        
        // Optimized sorting: Pre-compute values for better performance
        switch sortOption {
        case .dateDescending:
            result.sort { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
        case .dateAscending:
            result.sort { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }
        case .strengthDescending:
            result.sort { $0.connectionStrength > $1.connectionStrength }
        case .strengthAscending:
            result.sort { $0.connectionStrength < $1.connectionStrength }
        case .titleAscending:
            result.sort { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }
        case .titleDescending:
            result.sort { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedDescending }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                if filteredAndSortedEchoes.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        searchBar
                        filterAndSortBar
                        
                        ScrollView {
                            LazyVStack(spacing: AppTheme.spacing) {
                                ForEach(filteredAndSortedEchoes) { echo in
                                    ModernEchoCard(echo: echo) {
                                        selectedEcho = echo
                                    }
                                    .padding(.horizontal, AppTheme.padding)
                                }
                            }
                            .padding(.vertical, AppTheme.spacing)
                            .padding(.bottom, 20)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationTitle("All Echoes")
            .navigationBarTitleDisplayMode(.large)
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
            .sheet(isPresented: $showSortSheet) {
                sortSheet
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
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
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityHidden(true)
            
            TextField("Search echoes...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .rounded))
                .accessibilityLabel("Search echoes")
                .accessibilityHint("Type to search through your echoes by title, situation, trigger, or insight")
                .submitLabel(.search)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                        .accessibilityLabel("Clear search")
                }
            }
        }
        .padding(AppTheme.spacing)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardMaterial)
        )
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, AppTheme.spacing)
    }
    
    // MARK: - Filter and Sort Bar
    private var filterAndSortBar: some View {
        HStack(spacing: AppTheme.spacing) {
            Button(action: {
                showFilterSheet = true
                HapticFeedback.selection()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(filterOption.rawValue)
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(filterOption == .all ? AppTheme.textPrimary : AppTheme.accentColor)
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(filterOption == .all ? AppTheme.surfaceColor : AppTheme.accentColor.opacity(0.15))
                )
            }
            
            Button(action: {
                showSortSheet = true
                HapticFeedback.selection()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sortOption.rawValue)
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppTheme.cardMaterial)
                )
            }
            
            Spacer()
            
            Text("\(filteredAndSortedEchoes.count)")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.bottom, AppTheme.spacing)
    }
    
    // MARK: - Sort Sheet
    private var sortSheet: some View {
        NavigationStack {
            List {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        sortOption = option
                        showSortSheet = false
                        HapticFeedback.selection()
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundStyle(AppTheme.textPrimary)
                            
                            Spacer()
                            
                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showSortSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationStack {
            List {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        filterOption = option
                        showFilterSheet = false
                        HapticFeedback.selection()
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundStyle(AppTheme.textPrimary)
                            
                            Spacer()
                            
                            if filterOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilterSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            Image(systemName: searchText.isEmpty ? "magnifyingglass" : "tray")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.primaryColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No echoes yet" : "No results found")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text(searchText.isEmpty ? "Create your first echo to get started" : "Try adjusting your search or filters")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.paddingLarge)
        }
        .padding(.vertical, AppTheme.paddingLarge * 2)
    }
}

#Preview {
    AllEchoesView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
