import SwiftUI
import CoreData

struct EmotionalTonesManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EmotionalTone.name, ascending: true)],
        animation: .default
    ) private var tones: FetchedResults<EmotionalTone>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialEcho.createdAt, ascending: false)],
        animation: .default
    ) private var echoes: FetchedResults<FinancialEcho>
    
    @State private var showAddTone = false
    @State private var selectedTone: EmotionalTone?
    
    var toneFrequency: [UUID: Int] {
        var frequency: [UUID: Int] = [:]
        for echo in echoes {
            guard let tonesArray = echo.value(forKey: "emotionalTones") as? [String] else {
                continue
            }
            for toneIdString in tonesArray {
                guard let toneId = UUID(uuidString: toneIdString) else {
                    continue
                }
                let currentCount = frequency[toneId] ?? 0
                frequency[toneId] = currentCount + 1
            }
        }
        return frequency
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundIvory
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        DisclaimerText()
                            .padding(.top, 20)
                        
                        statsSection
                        
                        tonesListSection
                    }
                }
            }
            .navigationTitle("Emotional Tones")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddTone) {
                ToneFormView()
            }
            .sheet(item: $selectedTone) { tone in
                ToneFormView(tone: tone)
            }
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Tone Statistics")
                .font(AppTheme.serifFontSmall)
                .foregroundColor(AppTheme.deepTeal)
            
            if let mostCommon = mostCommonTone {
                mostCommonToneView(mostCommon)
            }
        }
        .padding(.horizontal, AppTheme.padding)
    }
    
    private func mostCommonToneView(_ tone: EmotionalTone) -> some View {
        let frequency = tone.id.flatMap { toneFrequency[$0] } ?? 0
        
        return HStack {
            VStack(alignment: .leading) {
                Text("Most Common")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(tone.name ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.deepTeal)
            }
            
            Spacer()
            
            Text("\(frequency)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.warmAmber)
        }
        .padding(AppTheme.padding)
        .background(AppTheme.softSilver.opacity(0.2))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    private var tonesListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Tones")
                    .font(AppTheme.serifFontSmall)
                    .foregroundColor(AppTheme.deepTeal)
                
                Spacer()
                
                Button(action: {
                    showAddTone = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.deepTeal)
                }
            }
            .padding(.horizontal, AppTheme.padding)
            
            ForEach(tones) { tone in
                toneRow(for: tone)
                    .padding(.horizontal, AppTheme.padding)
            }
        }
        .padding(.bottom, 40)
    }
    
    private func toneRow(for tone: EmotionalTone) -> some View {
        let frequency = tone.id.flatMap { toneFrequency[$0] } ?? 0
        
        return ToneRow(tone: tone, frequency: frequency) {
            selectedTone = tone
        }
    }
    
    var mostCommonTone: EmotionalTone? {
        var maxFrequency = 0
        var mostCommon: EmotionalTone?
        
        for tone in tones {
            guard let toneId = tone.id else { continue }
            let frequency = toneFrequency[toneId] ?? 0
            if frequency > maxFrequency {
                maxFrequency = frequency
                mostCommon = tone
            }
        }
        
        return mostCommon
    }
}

struct ToneRow: View {
    let tone: EmotionalTone
    let frequency: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let iconName = tone.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(toneColor)
                        .frame(width: 40, height: 40)
                        .background(toneColor.opacity(0.2))
                        .cornerRadius(20)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tone.name ?? "Unknown")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.deepTeal)
                    
                    if let description = tone.descriptionText {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(frequency)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.warmAmber)
            }
            .padding(AppTheme.padding)
            .background(AppTheme.softSilver.opacity(0.2))
            .cornerRadius(AppTheme.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var toneColor: Color {
        if let hex = tone.colorHex {
            return Color(hex: hex)
        }
        return AppTheme.deepTeal
    }
}

struct ToneFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let tone: EmotionalTone?
    
    @State private var name: String = ""
    @State private var colorHex: String = "0A4D5E"
    @State private var iconName: String = "circle.fill"
    @State private var description: String = ""
    
    init(tone: EmotionalTone? = nil) {
        self.tone = tone
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundIvory
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        DisclaimerText()
                            .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tone Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.deepTeal)
                            
                            TextField("Enter tone name", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color (Hex)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.deepTeal)
                            
                            HStack {
                                TextField("0A4D5E", text: $colorHex)
                                    .textFieldStyle(.roundedBorder)
                                
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 40, height: 40)
                            }
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon (SF Symbol)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.deepTeal)
                            
                            TextField("circle.fill", text: $iconName)
                                .textFieldStyle(.roundedBorder)
                            
                            Image(systemName: iconName)
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: colorHex))
                                .padding()
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.deepTeal)
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.softSilver, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, AppTheme.padding)
                        
                        Button(action: saveTone) {
                            Text(tone == nil ? "Create Tone" : "Update Tone")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.deepTeal)
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                        .padding(.horizontal, AppTheme.padding)
                        .padding(.bottom, 40)
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1.0)
                    }
                }
            }
            .navigationTitle(tone == nil ? "New Tone" : "Edit Tone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let tone = tone {
                    name = tone.name ?? ""
                    colorHex = tone.colorHex ?? "0A4D5E"
                    iconName = tone.iconName ?? "circle.fill"
                    description = tone.descriptionText ?? ""
                }
            }
        }
    }
    
    private func saveTone() {
        let toneToSave: EmotionalTone
        
        if let tone = tone {
            toneToSave = tone
        } else {
            toneToSave = EmotionalTone(context: viewContext)
            toneToSave.id = UUID()
        }
        
        toneToSave.name = name
        toneToSave.colorHex = colorHex
        toneToSave.iconName = iconName
        toneToSave.descriptionText = description.isEmpty ? nil : description
        
        CoreDataStack.shared.save()
        dismiss()
    }
}

#Preview {
    EmotionalTonesManagerView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
