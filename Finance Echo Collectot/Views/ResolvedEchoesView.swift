import SwiftUI
import CoreData

struct ResolvedEchoesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialEcho.resolvedDate, ascending: false)],
        predicate: NSPredicate(format: "isResolved == YES"),
        animation: .default
    ) private var resolvedEchoes: FetchedResults<FinancialEcho>
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundIvory
                    .ignoresSafeArea()
                
                if resolvedEchoes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.sageGreen.opacity(0.5))
                        
                        Text("No resolved echoes yet")
                            .font(AppTheme.serifFontSmall)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            DisclaimerText()
                                .padding(.top, 20)
                            
                            ForEach(resolvedEchoes) { echo in
                                ResolvedEchoCard(echo: echo)
                                    .padding(.horizontal, AppTheme.padding)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Resolved Echoes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ResolvedEchoCard: View {
    let echo: FinancialEcho
    @State private var showDetail = false
    
    var body: some View {
        Button(action: {
            showDetail = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(echo.title ?? "Untitled Echo")
                            .font(AppTheme.serifFontSmall)
                            .foregroundColor(AppTheme.deepTeal)
                        
                        if let resolvedDate = echo.resolvedDate {
                            Text("Resolved on \(resolvedDate, style: .date)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.sageGreen)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.sageGreen)
                }
                
                // Progress visualization
                ProgressVisualization(echo: echo)
            }
            .padding(AppTheme.padding)
            .background(
                LinearGradient(
                    colors: [AppTheme.sageGreen.opacity(0.1), AppTheme.backgroundIvory],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.sageGreen.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            EchoDetailView(echo: echo)
        }
    }
}

struct ProgressVisualization: View {
    let echo: FinancialEcho
    
    var body: some View {
        HStack(spacing: 12) {
            // Before (red fade)
            VStack(alignment: .leading, spacing: 4) {
                Text("Before")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.6), Color.orange.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 30)
            }
            
            Image(systemName: "arrow.right")
                .foregroundColor(AppTheme.sageGreen)
            
            // After (green fade)
            VStack(alignment: .leading, spacing: 4) {
                Text("After")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.sageGreen.opacity(0.6), AppTheme.sageGreen.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 30)
            }
        }
    }
}

#Preview {
    ResolvedEchoesView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
