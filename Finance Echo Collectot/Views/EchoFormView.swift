import SwiftUI
import CoreData
import PhotosUI

// MARK: - Professional Echo Form View
struct EchoFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let echo: FinancialEcho?
    
    @State private var title: String = ""
    @State private var pastDate: Date = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
    @State private var pastSituation: String = ""
    @State private var currentTrigger: String = ""
    @State private var connectionStrength: Double = 5.0
    @State private var insight: String = ""
    @State private var selectedTones: Set<UUID> = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var parentEcho: FinancialEcho?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, pastSituation, currentTrigger, insight
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EmotionalTone.name, ascending: true)],
        animation: .default
    ) private var tones: FetchedResults<EmotionalTone>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialEcho.createdAt, ascending: false)],
        animation: .default
    ) private var allEchoes: FetchedResults<FinancialEcho>
    
    init(echo: FinancialEcho? = nil) {
        self.echo = echo
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                formContent
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(echo == nil ? "New Echo" : "Edit Echo")
        .navigationBarBackButtonHidden(false)
        .onAppear {
            if let echo = echo {
                loadEcho(echo)
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
    
    // MARK: - Form Content
    private var formContent: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            DisclaimerText()
                .padding(.top, AppTheme.spacing)
            
            titleField
            pastDateField
            pastSituationField
            currentTriggerField
            connectionStrengthField
            insightField
            emotionalTonesSection
            parentEchoSection
            photoSection
            saveButton
        }
        .padding(.bottom, AppTheme.paddingLarge)
    }
    
    // MARK: - Title Field
    private var titleField: some View {
        ModernFormField(
            label: "Echo Title",
            icon: "text.book.closed.fill"
        ) {
            TextField("Enter echo title", text: $title)
                .font(.system(.body, design: .rounded))
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .pastSituation
                }
        }
    }
    
    // MARK: - Past Date Field
    private var pastDateField: some View {
        ModernFormField(
            label: "Past Event Date",
            icon: "calendar"
        ) {
            DatePicker("", selection: $pastDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(AppTheme.accentColor)
        }
    }
    
    // MARK: - Past Situation Field
    private var pastSituationField: some View {
        ModernFormField(
            label: "Past Decision / Situation",
            icon: "clock.arrow.circlepath"
        ) {
            TextEditor(text: $pastSituation)
                .font(.system(.body, design: .serif))
                .frame(minHeight: 120)
                .focused($focusedField, equals: .pastSituation)
                .scrollContentBackground(.hidden)
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
                .focused($focusedField, equals: .currentTrigger)
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
                // Slider
                Slider(value: $connectionStrength, in: 1...10, step: 1)
                    .tint(AppTheme.accentColor)
                    .padding(.horizontal, AppTheme.padding)
                    .onChange(of: connectionStrength) { _ in
                        HapticFeedback.selection()
                    }
                
                // Value display
                HStack {
                    Text("1")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(connectionStrength))")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: connectionStrength)
                    
                    Spacer()
                    
                    Text("10")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, AppTheme.padding)
                
                // Animated gauge
                strengthGauge
                    .padding(.horizontal, AppTheme.padding)
            }
        }
    }
    
    private var strengthGauge: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surfaceColor.opacity(0.5))
                    .frame(height: 24)
                
                // Progress
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.primaryColor,
                                AppTheme.accentColor
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * CGFloat(connectionStrength) / 10.0,
                        height: 24
                    )
                    .animation(AppTheme.springAnimation, value: connectionStrength)
            }
        }
        .frame(height: 24)
    }
    
    // MARK: - Insight Field
    private var insightField: some View {
        ModernFormField(
            label: "Lesson / Insight (Optional)",
            icon: "lightbulb.fill"
        ) {
            TextEditor(text: $insight)
                .font(.system(.body, design: .serif))
                .frame(minHeight: 100)
                .focused($focusedField, equals: .insight)
                .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - Emotional Tones Section
    @ViewBuilder
    private var emotionalTonesSection: some View {
        if !tones.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.accentColor)
                    
                    Text("Emotional Tones")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, AppTheme.padding)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacing) {
                        ForEach(tones) { tone in
                            toneChipView(for: tone)
                        }
                    }
                    .padding(.horizontal, AppTheme.padding)
                }
            }
        }
    }
    
    private func toneChipView(for tone: EmotionalTone) -> some View {
        let toneId = tone.id ?? UUID()
        let isSelected = selectedTones.contains(toneId)
        
        return Button(action: {
            HapticFeedback.impact(.light)
            if isSelected {
                selectedTones.remove(toneId)
            } else {
                selectedTones.insert(toneId)
            }
        }) {
            HStack(spacing: 6) {
                if let iconName = tone.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text(tone.name ?? "Unknown")
                    .font(.system(.caption, design: .rounded, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        (toneColor(for: tone).opacity(0.25)) :
                        AppTheme.surfaceColor.opacity(0.5)
                    )
            )
            .foregroundStyle(
                isSelected ?
                toneColor(for: tone) :
                AppTheme.textSecondary
            )
            .overlay(
                Capsule()
                    .stroke(
                        toneColor(for: tone).opacity(isSelected ? 0.6 : 0.2),
                        lineWidth: isSelected ? 2 : 1.5
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(AppTheme.springAnimation, value: isSelected)
        }
        .buttonStyle(.plain)
    }
    
    private func toneColor(for tone: EmotionalTone) -> Color {
        if let hex = tone.colorHex {
            return Color(hex: hex)
        }
        return AppTheme.primaryColor
    }
    
    // MARK: - Parent Echo Section
    @ViewBuilder
    private var parentEchoSection: some View {
        if !allEchoes.isEmpty {
            ModernFormField(
                label: "Link to Previous Echo (Optional)",
                icon: "link.circle.fill"
            ) {
                Picker("Parent Echo", selection: $parentEcho) {
                    Text("None").tag(nil as FinancialEcho?)
                    ForEach(allEchoes) { echo in
                        Text(echo.title ?? "Untitled").tag(echo as FinancialEcho?)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.accentColor)
            }
        }
    }
    
    // MARK: - Photo Section
    private var photoSection: some View {
        ModernFormField(
            label: "Photo (Optional)",
            icon: "photo.fill"
        ) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Group {
                    if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    } else {
                        VStack(spacing: AppTheme.spacing) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            Text("Select Photo")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(width: 200, height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .fill(AppTheme.surfaceColor.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .strokeBorder(
                                            AppTheme.textSecondary.opacity(0.2),
                                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                        )
                                )
                        )
                    }
                }
            }
            .onChange(of: selectedPhoto) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                        HapticFeedback.impact(.light)
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveEcho) {
            HStack(spacing: AppTheme.spacing) {
                Image(systemName: echo == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(echo == nil ? "Create Echo" : "Update Echo")
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
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPastSituation = pastSituation.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrentTrigger = currentTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedTitle.isEmpty &&
               !trimmedPastSituation.isEmpty &&
               !trimmedCurrentTrigger.isEmpty &&
               trimmedTitle.count <= 200 &&
               trimmedPastSituation.count <= 5000 &&
               trimmedCurrentTrigger.count <= 5000 &&
               pastDate <= Date()
    }
    
    // MARK: - Load Echo
    private func loadEcho(_ echo: FinancialEcho) {
        title = echo.title ?? ""
        pastDate = echo.pastDate ?? Date()
        pastSituation = echo.pastSituation ?? ""
        currentTrigger = echo.currentTrigger ?? ""
        connectionStrength = Double(echo.connectionStrength)
        insight = echo.insight ?? ""
        photoData = echo.photoData
        parentEcho = echo.parentEcho
        
        if let tones = echo.value(forKey: "emotionalTones") as? [String] {
            selectedTones = Set(tones.compactMap { UUID(uuidString: $0) })
        } else {
            selectedTones = []
        }
    }
    
    // MARK: - Save Echo
    private func saveEcho() {
        // Enhanced validation
        guard validateForm() else {
            HapticFeedback.notification(.error)
            return
        }
        
        // Create or update echo
        let echoToSave: FinancialEcho
        
        if let echo = echo {
            echoToSave = echo
        } else {
            echoToSave = FinancialEcho(context: viewContext)
            echoToSave.id = UUID()
            echoToSave.createdAt = Date()
            echoToSave.isResolved = false // Required field - must be set for new echoes
        }
        
        // Trim whitespace and validate length
        echoToSave.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        echoToSave.pastDate = pastDate
        echoToSave.pastSituation = pastSituation.trimmingCharacters(in: .whitespacesAndNewlines)
        echoToSave.currentTrigger = currentTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        echoToSave.connectionStrength = Int16(max(1, min(10, connectionStrength)))
        echoToSave.insight = insight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : insight.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Set emotionalTones as Transformable array
        // Transformable attributes with NSSecureUnarchiveFromDataTransformer need NSArray
        let tonesArray = selectedTones.map { $0.uuidString }
        if tonesArray.isEmpty {
            echoToSave.setValue(nil, forKey: "emotionalTones")
        } else {
            // Use NSArray for Core Data Transformable compatibility
            echoToSave.setValue(NSArray(array: tonesArray), forKey: "emotionalTones")
        }
        
        echoToSave.photoData = photoData
        echoToSave.parentEcho = parentEcho
        
        // Save with explicit context refresh
        do {
            // Save the context
            try viewContext.save()
            
            // Process pending changes to trigger UI updates
            viewContext.processPendingChanges()
            
            HapticFeedback.notification(.success)
            
            // Dismiss - should work correctly
            dismiss()
        } catch {
            print("Error saving echo: \(error.localizedDescription)")
            // Rollback on error
            viewContext.rollback()
            HapticFeedback.notification(.error)
            // Don't dismiss on error - let user fix and try again
        }
    }
    
    // MARK: - Validation
    private func validateForm() -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPastSituation = pastSituation.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrentTrigger = currentTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check required fields
        guard !trimmedTitle.isEmpty,
              !trimmedPastSituation.isEmpty,
              !trimmedCurrentTrigger.isEmpty else {
            return false
        }
        
        // Check length limits
        guard trimmedTitle.count <= 200,
              trimmedPastSituation.count <= 5000,
              trimmedCurrentTrigger.count <= 5000,
              (insight.isEmpty || insight.count <= 5000) else {
            return false
        }
        
        // Check date validity
        guard pastDate <= Date() else {
            return false
        }
        
        return true
    }
}

// MARK: - Modern Form Field Component
struct ModernFormField<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.accentColor)
                
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, AppTheme.padding)
            
            content
                .padding(AppTheme.padding)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, AppTheme.padding)
        }
    }
}

// MARK: - Tone Chip (for use in other views)
struct ToneChip: View {
    let tone: EmotionalTone
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName = tone.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                }
                
                Text(tone.name ?? "Unknown")
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? toneColor.opacity(0.3) : AppTheme.softSilver.opacity(0.2))
            .foregroundColor(isSelected ? toneColor : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(toneColor, lineWidth: isSelected ? 2 : 0)
            )
        }
    }
    
    var toneColor: Color {
        if let hex = tone.colorHex {
            return Color(hex: hex)
        }
        return AppTheme.deepTeal
    }
}

#Preview {
    EchoFormView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
