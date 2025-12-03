import CoreData

/// Класс для управления Core Data Stack
/// Предоставляет единый Persistent Container для работы с тремя типами Store:
/// - TrackerStore (для работы с TrackerCoreData)
/// - TrackerCategoryStore (для работы с TrackerCategoryCoreData)
/// - TrackerRecordStore (для работы с TrackerRecordCoreData)
final class CoreDataStack {
    
    // MARK: - Singleton
    static let shared = CoreDataStack()
    
    // MARK: - Properties
    
    /// Persistent Container для управления всеми Store
    /// Один контейнер для всей модели данных
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TrackerDataModel")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Не удалось загрузить хранилище данных: \(error)")
            }
        }
        
        return container
    }()
    
    /// Главный контекст для работы с данными
    /// Используйте этот контекст для чтения и записи данных
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Save Context
    
    /// Сохраняет изменения в контексте
    /// Вызывается автоматически при завершении приложения и переходе в фон
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

// MARK: - Пример использования с Dependency Injection
/*
 Пример использования в Store классах:
 
 final class TrackerStore {
     private let context: NSManagedObjectContext
     
     // Constructor Injection - передача контекста через init
     init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
         self.context = context
     }
     
     func fetchTrackers() -> [TrackerCoreData] {
         // Работа с контекстом
     }
 }
 
 Использование:
 let trackerStore = TrackerStore(context: CoreDataStack.shared.context)
 */

