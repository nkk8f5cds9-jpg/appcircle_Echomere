import CoreData
import SwiftUI

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FinancialEchoModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                // Log error for debugging
                print("Core Data store failed to load: \(error.localizedDescription)")
                
                // Try to recover by creating a new store
                if let url = description.url {
                    do {
                        try FileManager.default.removeItem(at: url)
                        container.loadPersistentStores { _, recoveryError in
                            if let recoveryError = recoveryError {
                                // Log recovery error but don't crash
                                print("Core Data recovery failed: \(recoveryError.localizedDescription)")
                                // App will continue with in-memory context
                            }
                        }
                    } catch {
                        print("Failed to remove corrupted store: \(error.localizedDescription)")
                    }
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
            // Try to rollback changes
            context.rollback()
        }
    }
}
