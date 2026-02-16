import SwiftUI
import CoreData
import UserNotifications

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("theme") private var theme = "system"
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showResetConfirmation = false
    @State private var resetConfirmationCount = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundIvory
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        DisclaimerText()
                            .padding(.top, 20)
                        
                        // Theme
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Theme")
                                .font(AppTheme.serifFontSmall)
                                .foregroundColor(AppTheme.deepTeal)
                            
                            Picker("Theme", selection: $theme) {
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                                Text("System").tag("system")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        // Reminders
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Weekly Reflection Reminder")
                                .font(AppTheme.serifFontSmall)
                                .foregroundColor(AppTheme.deepTeal)
                            
                            Toggle("Enable weekly reminders", isOn: $reminderEnabled)
                                .onChange(of: reminderEnabled) { enabled in
                                    if enabled {
                                        requestNotificationPermission()
                                        scheduleReminder()
                                    } else {
                                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                                    }
                                }
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        // Data Management
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Data Management")
                                .font(AppTheme.serifFontSmall)
                                .foregroundColor(AppTheme.deepTeal)
                            
                            Button(action: {
                                exportData()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export Data Backup")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding(AppTheme.padding)
                                .background(AppTheme.softSilver.opacity(0.2))
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                            
                            Button(action: {
                                importData()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import Data Backup")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding(AppTheme.padding)
                                .background(AppTheme.softSilver.opacity(0.2))
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        // Reset
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Danger Zone")
                                .font(AppTheme.serifFontSmall)
                                .foregroundColor(.red)
                            
                            Button(action: {
                                resetConfirmationCount += 1
                                if resetConfirmationCount >= 3 {
                                    showResetConfirmation = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Reset All Data")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding(AppTheme.padding)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                            
                            if resetConfirmationCount > 0 && resetConfirmationCount < 3 {
                                Text("Tap \(3 - resetConfirmationCount) more time\(3 - resetConfirmationCount == 1 ? "" : "s") to confirm")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        // App Info
                        VStack(spacing: 8) {
                            Text("Financial Echo Collector")
                                .font(AppTheme.serifFontSmall)
                                .foregroundColor(AppTheme.deepTeal)
                            
                            Text("Version 1.0.0")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("A private reflection journal")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {
                    resetConfirmationCount = 0
                }
                Button("Reset", role: .destructive) {
                    resetAllData()
                    resetConfirmationCount = 0
                }
            } message: {
                Text("This will permanently delete all your echoes and tones. This action cannot be undone.")
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                scheduleReminder()
            }
        }
    }
    
    private func scheduleReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Reflection"
        content.body = "Take a moment to reflect on your financial echoes"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyReflection", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func exportData() {
        // Export Core Data to JSON
        let request = FinancialEcho.fetchRequest()
        let echoes = (try? viewContext.fetch(request)) ?? []
        
        let echoData = echoes.map { echo in
            [
                "id": (echo.id ?? UUID()).uuidString,
                "title": echo.title ?? "",
                "pastDate": (echo.pastDate ?? Date()).ISO8601Format(),
                "pastSituation": echo.pastSituation ?? "",
                "currentTrigger": echo.currentTrigger ?? "",
                "connectionStrength": echo.connectionStrength,
                "insight": echo.insight ?? "",
                "emotionalTones": (echo.value(forKey: "emotionalTones") as? [String]) ?? [],
                "isResolved": echo.isResolved,
                "resolvedDate": echo.resolvedDate?.ISO8601Format() ?? "",
                "createdAt": (echo.createdAt ?? Date()).ISO8601Format()
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: echoData, options: .prettyPrinted) {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("FinancialEchoes_Backup_\(Date().formatted(date: .numeric, time: .omitted)).json")
            
            try? jsonData.write(to: tempURL)
            
            let shareSheet = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(shareSheet, animated: true)
            }
        }
    }
    
    private func importData() {
        // Implementation for importing data
        // This would require a document picker
    }
    
    private func resetAllData() {
        let echoRequest = FinancialEcho.fetchRequest()
        let toneRequest = EmotionalTone.fetchRequest()
        
        if let echoes = try? viewContext.fetch(echoRequest) {
            echoes.forEach { viewContext.delete($0) }
        }
        
        if let tones = try? viewContext.fetch(toneRequest) {
            tones.forEach { viewContext.delete($0) }
        }
        
        CoreDataStack.shared.save()
        resetConfirmationCount = 0
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
