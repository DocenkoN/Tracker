import CoreData

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TrackerDataModel")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Ошибка загрузки хранилища данных: \(error)")
                print("   Описание: \(description)")
                // Не используем fatalError, чтобы приложение не падало
                // Вместо этого логируем ошибку
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
                print("❌ Ошибка сохранения контекста: \(nsError)")
                print("   UserInfo: \(nsError.userInfo)")
                // Не используем fatalError, чтобы приложение не падало
                // Вместо этого логируем ошибку
            }
        }
    }
}
