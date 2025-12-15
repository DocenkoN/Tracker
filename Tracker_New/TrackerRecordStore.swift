import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func trackerRecordStoreDidUpdate()
}

final class TrackerRecordStore: NSObject {
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>?
    weak var delegate: TrackerRecordStoreDelegate?
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
    private func setupFetchedResultsController() {
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
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
    
    func getFetchedRecords() -> [TrackerRecordCoreData] {
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
    
    func filterRecords(by trackerId: UUID) {
        let predicate = NSPredicate(format: "tracker.id == %@", trackerId as CVarArg)
        updatePredicate(predicate: predicate)
    }
    
    func clearFilter() {
        updatePredicate(predicate: nil)
    }
    
    private func performFetch() {
        do {
            try fetchedResultsController?.performFetch()
            delegate?.trackerRecordStoreDidUpdate()
        } catch {
            print("Ошибка при выполнении fetch: \(error)")
        }
    }
    
    func createRecord(trackerId: UUID, date: Date) throws -> TrackerRecordCoreData {
        if let existingRecord = try? fetchRecord(trackerId: trackerId, date: date) {
            return existingRecord
        }
        
        let trackerRequest = TrackerCoreData.fetchRequest()
        trackerRequest.predicate = NSPredicate(format: "id == %@", trackerId as CVarArg)
        guard let tracker = try context.fetch(trackerRequest).first else {
            throw NSError(domain: "TrackerRecordStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Трекер не найден"])
        }
        
        let recordCoreData = TrackerRecordCoreData(context: context)
        recordCoreData.id = UUID()
        recordCoreData.date = date
        recordCoreData.tracker = tracker
        
        try context.save()
        return recordCoreData
    }
    
    func fetchRecords() throws -> [TrackerRecordCoreData] {
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try context.fetch(request)
    }
    
    func fetchRecord(trackerId: UUID, date: Date) throws -> TrackerRecordCoreData? {
        let request = TrackerRecordCoreData.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(
            format: "tracker.id == %@ AND date >= %@ AND date < %@",
            trackerId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        return try context.fetch(request).first
    }
    
    func fetchRecords(for trackerId: UUID) throws -> [TrackerRecordCoreData] {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker.id == %@", trackerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try context.fetch(request)
    }
    
    func isRecordExists(trackerId: UUID, date: Date) throws -> Bool {
        return try fetchRecord(trackerId: trackerId, date: date) != nil
    }
    
    func deleteRecord(trackerId: UUID, date: Date) throws {
        guard let record = try fetchRecord(trackerId: trackerId, date: date) else {
            return
        }
        
        context.delete(record)
        try context.save()
    }
    
    func deleteRecords(for trackerId: UUID) throws {
        let records = try fetchRecords(for: trackerId)
        records.forEach { context.delete($0) }
        try context.save()
    }
    
    func convertToRecord(_ recordCoreData: TrackerRecordCoreData) -> TrackerRecord? {
        guard let id = recordCoreData.id,
              let date = recordCoreData.date else {
            return nil
        }
        
        return TrackerRecord(id: id, date: date)
    }
    
    func convertToRecords(_ recordsCoreData: [TrackerRecordCoreData]) -> Set<TrackerRecord> {
        return Set(recordsCoreData.compactMap { convertToRecord($0) })
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerRecordStoreDidUpdate()
    }
}


