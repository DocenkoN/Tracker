import CoreData

protocol TrackerCategoryStoreDelegate: AnyObject {
    func trackerCategoryStoreDidUpdate()
}

final class TrackerCategoryStore: NSObject {
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>?
    weak var delegate: TrackerCategoryStoreDelegate?
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
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
    
    func getFetchedCategories() -> [TrackerCategoryCoreData] {
        return fetchedResultsController?.fetchedObjects ?? []
    }
    
    func updatePredicate(predicate: NSPredicate?) {
        fetchedResultsController?.fetchRequest.predicate = predicate
        performFetch()
    }
    
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
    
    func createCategory(title: String) throws -> TrackerCategoryCoreData {
        if let existingCategory = try? fetchCategory(by: title) {
            return existingCategory
        }
        
        let categoryCoreData = TrackerCategoryCoreData(context: context)
        categoryCoreData.title = title
        
        try context.save()
        return categoryCoreData
    }
    
    func fetchCategories() throws -> [TrackerCategoryCoreData] {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return try context.fetch(request)
    }
    
    func fetchCategory(by title: String) throws -> TrackerCategoryCoreData? {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        return try context.fetch(request).first
    }
    
    func updateCategory(_ categoryCoreData: TrackerCategoryCoreData, title: String) throws {
        categoryCoreData.title = title
        try context.save()
    }
    
    func deleteCategory(_ categoryCoreData: TrackerCategoryCoreData) throws {
        context.delete(categoryCoreData)
        try context.save()
    }
    
    func convertToCategory(_ categoryCoreData: TrackerCategoryCoreData, trackerStore: TrackerStore) -> TrackerCategory? {
        guard let title = categoryCoreData.title else {
            return nil
        }
        
        let trackers = (categoryCoreData.trackers as? Set<TrackerCoreData> ?? [])
            .compactMap { trackerStore.convertToTracker($0) }
        
        return TrackerCategory(title: title, trackers: trackers)
    }
    
    func convertToCategories(_ categoriesCoreData: [TrackerCategoryCoreData], trackerStore: TrackerStore) -> [TrackerCategory] {
        return categoriesCoreData.compactMap { convertToCategory($0, trackerStore: trackerStore) }
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerCategoryStoreDidUpdate()
    }
}


