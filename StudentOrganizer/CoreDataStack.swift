import CoreData

/// One shared object that owns the Core Data "stack" (model + database + context).
/// Every screen talks to the database through CoreDataStack.shared, so there is
/// only ever one context and no screen sees stale or duplicated objects.
final class CoreDataStack {

    static let shared = CoreDataStack()

    /// Loads StudentOrganizer.xcdatamodeld and creates the SQLite file on the device.
    let container: NSPersistentContainer

    /// The "scratchpad" where we create, change, and delete objects before saving.
    var context: NSManagedObjectContext { container.viewContext }

    private init() {
        // The name MUST match the .xcdatamodeld file name exactly, or the app crashes.
        container = NSPersistentContainer(name: "StudentOrganizer")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                // If the database cannot load, the app cannot work at all.
                fatalError("Core Data failed to load: \(error)")
            }
            print("Database file: \(storeDescription.url?.path ?? "unknown")")
        }
    }

    /// Writes any pending changes to the database file.
    /// Skips the write when nothing changed, which avoids needless disk work.
    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save failed: \(error)")
        }
    }
}
