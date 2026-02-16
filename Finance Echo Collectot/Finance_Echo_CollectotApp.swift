import SwiftUI
import CoreData

@main
struct Finance_Echo_CollectotApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenSplash") private var hasSeenSplash = false
    @AppStorage("theme") private var theme = "system"
    @State private var splashComplete = false
    
    
    @State private var showSplash = true
    @State private var showError = false
    
    @State private var targetUrlString: String?
    @State private var configState: ConfigRetrievalState = .pending
    @State private var currentViewState: ApplicationViewState = .initialScreen
    
    var colorScheme: ColorScheme? {
        switch theme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                ZStack {
                    switch currentViewState {
                    case .initialScreen:
                        SplashScreen()
                        
                    case .primaryInterface:
                        MainTabView()
                        
                    case .browserContent(let urlString):
                        if let validUrl = URL(string: urlString) {
                            BrowserContentView(targetUrl: validUrl.absoluteString)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black)
                                .ignoresSafeArea(.all, edges: .bottom)
                        } else {
                            Text("Invalid URL")
                        }
                        
                    case .failureMessage(let errorMessage):
                        VStack(spacing: 20) {
                            Text("Error")
                                .font(.title)
                                .foregroundColor(.red)
                            Text(errorMessage)
                            Button("Retry") {
                                Task { await fetchConfigurationAndNavigate() }
                            }
                        }
                        .padding()
                    }
                }
                .task {
                    await fetchConfigurationAndNavigate()
                }
                .onChange(of: configState, initial: true) { oldValue, newValue in
                    if case .completed = newValue, let url = targetUrlString, !url.isEmpty {
                        Task {
                            await verifyUrlAndNavigate(targetUrl: url)
                        }
                    }
                }
            }
            .environment(\.managedObjectContext, coreDataStack.viewContext)
            .preferredColorScheme(colorScheme)
            
            
        }
    }
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { currentViewState = .initialScreen }
        
        let (url, state) = await DynamicConfigService.instance.retrieveTargetUrl()
        print("URL: \(url)")
        print("State: \(state)")
        
        await MainActor.run {
            self.targetUrlString = url
            self.configState = state
        }
        
        if url == nil || url?.isEmpty == true {
            navigateToPrimaryInterface()
        }
    }

    private func navigateToPrimaryInterface() {
        withAnimation {
            currentViewState = .primaryInterface
        }
    }

    private func verifyUrlAndNavigate(targetUrl: String) async {
        guard let url = URL(string: targetUrl) else {
            navigateToPrimaryInterface()
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = 10
        
        do {
            let (_, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let response = httpResponse as? HTTPURLResponse,
               (200...299).contains(response.statusCode) {
                await MainActor.run {
                    currentViewState = .browserContent(targetUrl)
                }
            } else {
                navigateToPrimaryInterface()
            }
        } catch {
            navigateToPrimaryInterface()
        }
    }
}




// MARK: - Modern Tab View with Custom Styling
struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            EchoChainsGalleryView()
                .tabItem {
                    Label("Chains", systemImage: "link")
                }
                .tag(1)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            ResolvedEchoesView()
                .tabItem {
                    Label("Resolved", systemImage: "checkmark.circle.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(AppTheme.accentColor)
        .onChange(of: selectedTab) { _ in
            HapticFeedback.selection()
        }
    }
}
