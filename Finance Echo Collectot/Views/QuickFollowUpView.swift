import SwiftUI
import CoreData

// MARK: - Professional Quick Follow-up View
struct QuickFollowUpView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let parentEcho: FinancialEcho
    
    @State private var title: String = ""
    @State private var currentTrigger: String = ""
    @State private var connectionStrength: Double = 5.0
    @State private var showChainAnimation = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacingLarge) {
                        DisclaimerText()
                            .padding(.top, AppTheme.spacing)
                        
                        // Visual chain preview
                        if showChainAnimation {
                            chainPreview
                                .transition(.opacity.combined(with: .scale))
                        }
                        
                        titleField
                        currentTriggerField
                        connectionStrengthField
                        saveButton
                    }
                    .padding(.bottom, AppTheme.paddingLarge)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Follow-up Echo")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .onAppear {
                withAnimation(AppTheme.springAnimation.delay(0.3)) {
                    showChainAnimation = true
                }
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
    
    // MARK: - Chain Preview
    private var chainPreview: some View {
        VStack(spacing: AppTheme.spacing) {
            HStack(spacing: AppTheme.spacing) {
                EchoNode(title: parentEcho.title ?? "Parent Echo", isParent: true)
                
                // Animated connecting line
                ZStack {
                    Rectangle()
                        .fill(AppTheme.accentColor.opacity(0.3))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accentColor, AppTheme.accentColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .scaleEffect(x: showChainAnimation ? 1.0 : 0.0, anchor: .leading)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.7)
                            .delay(0.5),
                            value: showChainAnimation
                        )
                }
                .frame(width: 120)
                
                EchoNode(title: title.isEmpty ? "New Echo" : title, isParent: false)
            }
            .padding(AppTheme.padding)
        }
        .padding(.horizontal, AppTheme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, AppTheme.padding)
    }
    
    // MARK: - Title Field
    private var titleField: some View {
        ModernFormField(
            label: "Echo Title",
            icon: "text.book.closed.fill"
        ) {
            TextField("Enter echo title", text: $title)
                .font(.system(.body, design: .rounded))
                .focused($isFocused)
                .onChange(of: title) { _ in
                    withAnimation {
                        showChainAnimation = true
                    }
                }
        }
    }
    
    // MARK: - Current Trigger Field
    private var currentTriggerField: some View {
        ModernFormField(
            label: "Current Trigger",
            icon: "sparkles"
        ) {
            TextEditor(text: $currentTrigger)
                .font(.system(.body, design: .serif))
                .frame(minHeight: 120)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - Connection Strength Field
    private var connectionStrengthField: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Image(systemName: "gauge.high")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.accentColor)
                
                Text("Connection Strength")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, AppTheme.padding)
            
            VStack(spacing: AppTheme.spacing) {
                Slider(value: $connectionStrength, in: 1...10, step: 1)
                    .tint(AppTheme.accentColor)
                    .padding(.horizontal, AppTheme.padding)
                    .onChange(of: connectionStrength) { _ in
                        HapticFeedback.selection()
                    }
                
                HStack {
                    Text("1")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(connectionStrength))")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.numericText())
                    
                    Spacer()
                    
                    Text("10")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, AppTheme.padding)
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveFollowUp) {
            HStack(spacing: AppTheme.spacing) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Create Follow-up Echo")
                    .font(.system(.body, design: .rounded, weight: .semibold))
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
            .opacity(isFormValid ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isFormValid)
        .onTapGesture {
            if isFormValid {
                HapticFeedback.impact(.medium)
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !currentTrigger.isEmpty
    }
    
    // MARK: - Save Follow-up
    private func saveFollowUp() {
        let newEcho = FinancialEcho(context: viewContext)
        newEcho.id = UUID()
        newEcho.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        newEcho.pastDate = parentEcho.pastDate ?? Date()
        newEcho.pastSituation = parentEcho.pastSituation ?? ""
        newEcho.currentTrigger = currentTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        newEcho.connectionStrength = Int16(max(1, min(10, connectionStrength)))
        newEcho.createdAt = Date()
        newEcho.parentEcho = parentEcho
        
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            HapticFeedback.notification(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        } catch {
            print("Error saving follow-up echo: \(error.localizedDescription)")
            viewContext.rollback()
            HapticFeedback.notification(.error)
        }
    }
}

// MARK: - Echo Node Component
struct EchoNode: View {
    let title: String
    let isParent: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.spacing) {
            ZStack {
                Circle()
                    .fill(
                        isParent ?
                        AppTheme.primaryColor :
                        AppTheme.accentColor
                    )
                    .frame(width: 48, height: 48)
                    .shadow(
                        color: (isParent ? AppTheme.primaryColor : AppTheme.accentColor).opacity(0.4),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Image(systemName: isParent ? "circle.fill" : "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 90)
                .lineLimit(2)
        }
    }
}

#Preview {
    let context = CoreDataStack.shared.viewContext
    let echo = FinancialEcho(context: context)
    echo.id = UUID()
    echo.title = "Parent Echo"
    echo.createdAt = Date()
    
    return QuickFollowUpView(parentEcho: echo)
        .environment(\.managedObjectContext, context)
}
