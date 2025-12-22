import CoreData

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TrackerDataModel")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Не удалось загрузить хранилище данных: \(error)")
            }
        }
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Не удалось сохранить контекст: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
