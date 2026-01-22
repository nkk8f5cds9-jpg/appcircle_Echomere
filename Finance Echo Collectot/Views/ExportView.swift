import SwiftUI
import CoreData
import PDFKit

struct ExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialEcho.createdAt, ascending: false)],
        animation: .default
    ) private var echoes: FetchedResults<FinancialEcho>
    
    @State private var isExporting = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundIvory
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        DisclaimerText()
                            .padding(.top, 20)
                        
                        Text("Export & Reflection")
                            .font(AppTheme.serifFont)
                            .foregroundColor(AppTheme.deepTeal)
                            .padding(.horizontal, AppTheme.padding)
                        
                        // PDF Export
                        ExportOptionCard(
                            title: "PDF Export",
                            description: "Export all your echoes as a beautiful PDF booklet",
                            icon: "doc.text.fill",
                            action: {
                                exportPDF()
                            }
                        )
                        .padding(.horizontal, AppTheme.padding)
                        
                        // Share Single Chain
                        ExportOptionCard(
                            title: "Share Single Chain",
                            description: "Create an elegant card for one echo chain",
                            icon: "square.and.arrow.up",
                            action: {
                                // Implementation for sharing single chain
                            }
                        )
                        .padding(.horizontal, AppTheme.padding)
                        
                        // Video Recap
                        ExportOptionCard(
                            title: "60-Second Recap",
                            description: "Generate a contemplative video of your echoes",
                            icon: "video.fill",
                            action: {
                                // Implementation for video recap
                            }
                        )
                        .padding(.horizontal, AppTheme.padding)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Export & Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(
                get: { exportURL != nil },
                set: { if !$0 { exportURL = nil } }
            )) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func exportPDF() {
        isExporting = true
        
        do {
            let pdfData = try createPDF()
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("My_Financial_Echoes_\(Date().formatted(date: .numeric, time: .omitted)).pdf")
            
            try pdfData.write(to: tempURL)
            exportURL = tempURL
            HapticFeedback.notification(.success)
        } catch {
            print("Error exporting PDF: \(error.localizedDescription)")
            HapticFeedback.notification(.error)
            // In production, show user-friendly error message
        }
        
        isExporting = false
    }
    
    private func createPDF() throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Financial Echo Collector",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "My Financial Echoes"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        do {
            let data = renderer.pdfData { context in
                context.beginPage()
                
                var yPosition: CGFloat = 50
                
                // Title
                let title = "My Financial Echoes"
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Georgia", size: 32) ?? UIFont.systemFont(ofSize: 32),
                    .foregroundColor: UIColor(AppTheme.deepTeal)
                ]
                let titleSize = title.size(withAttributes: titleAttributes)
                title.draw(at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: yPosition), withAttributes: titleAttributes)
                yPosition += titleSize.height + 30
                
                // Echoes with error handling
                for echo in echoes {
                    if yPosition > pageHeight - 200 {
                        context.beginPage()
                        yPosition = 50
                    }
                    
                    let echoText = "\(echo.title ?? "Untitled")\n\(echo.pastSituation ?? "")\n\(echo.currentTrigger ?? "")"
                    let textAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont(name: "Georgia", size: 14) ?? UIFont.systemFont(ofSize: 14),
                        .foregroundColor: UIColor.black
                    ]
                    let textRect = CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 150)
                    echoText.draw(in: textRect, withAttributes: textAttributes)
                    yPosition += 160
                }
            }
            
            return data
        } catch {
            throw NSError(domain: "PDFExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF: \(error.localizedDescription)"])
        }
    }
}

struct ExportOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.warmAmber)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(AppTheme.serifFontSmall)
                        .foregroundColor(AppTheme.deepTeal)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(AppTheme.padding)
            .background(AppTheme.softSilver.opacity(0.2))
            .cornerRadius(AppTheme.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
