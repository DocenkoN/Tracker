import CoreData

/// Протокол делегата для получения обновлений от TrackerCategoryStore
protocol TrackerCategoryStoreDelegate: AnyObject {
    func trackerCategoryStoreDidUpdate()
}

/// Store для работы с TrackerCategoryCoreData Entity
/// Абстрагирует приложение от Core Data
final class TrackerCategoryStore: NSObject {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>?
    weak var delegate: TrackerCategoryStoreDelegate?
    
    // MARK: - Initialization
    
    /// Constructor Injection - передача контекста через init
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
    // MARK: - NSFetchedResultsController Setup
    
    private func setupFetchedResultsController() {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Ошибка при выполнении fetch: \(error)")
        }
    }
    
    /// Получает все категории через NSFetchedResultsController
    func getFetchedCategories() -> [TrackerCategoryCoreData] {
        return fetchedResultsController?.fetchedObjects ?? []
    }
    
    /// Обновляет предикат для фильтрации категорий
    func updatePredicate(predicate: NSPredicate?) {
        fetchedResultsController?.fetchRequest.predicate = predicate
        performFetch()
    }
    
    /// Обновляет сортировку
    func updateSortDescriptors(_ sortDescriptors: [NSSortDescriptor]) {
        fetchedResultsController?.fetchRequest.sortDescriptors = sortDescriptors
        performFetch()
    }
    
    private func performFetch() {
        do {
            try fetchedResultsController?.performFetch()
            delegate?.trackerCategoryStoreDidUpdate()
        } catch {
            print("Ошибка при выполнении fetch: \(error)")
        }
    }
    
    // MARK: - Create
    
    /// Создает новую категорию в Core Data
    func createCategory(title: String) throws -> TrackerCategoryCoreData {
        // Проверяем, существует ли уже категория с таким названием
        if let existingCategory = try? fetchCategory(by: title) {
            return existingCategory
        }
        
        let categoryCoreData = TrackerCategoryCoreData(context: context)
        categoryCoreData.title = title
        
        try context.save()
        return categoryCoreData
    }
    
    // MARK: - Read
    
    /// Получает все категории
    func fetchCategories() throws -> [TrackerCategoryCoreData] {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return try context.fetch(request)
    }
    
    /// Получает категорию по названию
    func fetchCategory(by title: String) throws -> TrackerCategoryCoreData? {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        return try context.fetch(request).first
    }
    
    // MARK: - Update
    
    /// Обновляет название категории
    func updateCategory(_ categoryCoreData: TrackerCategoryCoreData, title: String) throws {
        categoryCoreData.title = title
        try context.save()
    }
    
    // MARK: - Delete
    
    /// Удаляет категорию
    /// Внимание: при удалении категории трекеры не удаляются (deletionRule: Nullify)
    func deleteCategory(_ categoryCoreData: TrackerCategoryCoreData) throws {
        context.delete(categoryCoreData)
        try context.save()
    }
    
    // MARK: - Conversion Helpers
    
    /// Конвертирует TrackerCategoryCoreData в TrackerCategory
    func convertToCategory(_ categoryCoreData: TrackerCategoryCoreData, trackerStore: TrackerStore) -> TrackerCategory? {
        guard let title = categoryCoreData.title else {
            return nil
        }
        
        let trackers = (categoryCoreData.trackers as? Set<TrackerCoreData> ?? [])
            .compactMap { trackerStore.convertToTracker($0) }
        
        return TrackerCategory(title: title, trackers: trackers)
    }
    
    /// Конвертирует массив TrackerCategoryCoreData в массив TrackerCategory
    func convertToCategories(_ categoriesCoreData: [TrackerCategoryCoreData], trackerStore: TrackerStore) -> [TrackerCategory] {
        return categoriesCoreData.compactMap { convertToCategory($0, trackerStore: trackerStore) }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerCategoryStoreDidUpdate()
    }
}


