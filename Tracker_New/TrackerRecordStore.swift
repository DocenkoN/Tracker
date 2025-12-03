import CoreData

/// Протокол делегата для получения обновлений от TrackerRecordStore
protocol TrackerRecordStoreDelegate: AnyObject {
    func trackerRecordStoreDidUpdate()
}

/// Store для работы с TrackerRecordCoreData Entity
/// Абстрагирует приложение от Core Data
final class TrackerRecordStore: NSObject {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>?
    weak var delegate: TrackerRecordStoreDelegate?
    
    // MARK: - Initialization
    
    /// Constructor Injection - передача контекста через init
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
    // MARK: - NSFetchedResultsController Setup
    
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
    
    /// Получает все записи через NSFetchedResultsController
    func getFetchedRecords() -> [TrackerRecordCoreData] {
        return fetchedResultsController?.fetchedObjects ?? []
    }
    
    /// Обновляет предикат для фильтрации записей
    func updatePredicate(predicate: NSPredicate?) {
        fetchedResultsController?.fetchRequest.predicate = predicate
        performFetch()
    }
    
    /// Обновляет сортировку
    func updateSortDescriptors(_ sortDescriptors: [NSSortDescriptor]) {
        fetchedResultsController?.fetchRequest.sortDescriptors = sortDescriptors
        performFetch()
    }
    
    /// Фильтрует записи по ID трекера
    func filterRecords(by trackerId: UUID) {
        let predicate = NSPredicate(format: "tracker.id == %@", trackerId as CVarArg)
        updatePredicate(predicate: predicate)
    }
    
    /// Убирает фильтр, показывая все записи
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
    
    // MARK: - Create
    
    /// Создает новую запись о выполнении трекера
    func createRecord(trackerId: UUID, date: Date) throws -> TrackerRecordCoreData {
        // Проверяем, не существует ли уже запись для этого трекера на эту дату
        if let existingRecord = try? fetchRecord(trackerId: trackerId, date: date) {
            return existingRecord
        }
        
        // Получаем трекер
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
    
    // MARK: - Read
    
    /// Получает все записи
    func fetchRecords() throws -> [TrackerRecordCoreData] {
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try context.fetch(request)
    }
    
    /// Получает запись по ID трекера и дате
    func fetchRecord(trackerId: UUID, date: Date) throws -> TrackerRecordCoreData? {
        let request = TrackerRecordCoreData.fetchRequest()
        
        // Нормализуем дату до начала дня для сравнения
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
    
    /// Получает все записи для конкретного трекера
    func fetchRecords(for trackerId: UUID) throws -> [TrackerRecordCoreData] {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker.id == %@", trackerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try context.fetch(request)
    }
    
    /// Проверяет, выполнена ли запись для трекера на указанную дату
    func isRecordExists(trackerId: UUID, date: Date) throws -> Bool {
        return try fetchRecord(trackerId: trackerId, date: date) != nil
    }
    
    // MARK: - Delete
    
    /// Удаляет запись о выполнении трекера
    func deleteRecord(trackerId: UUID, date: Date) throws {
        guard let record = try fetchRecord(trackerId: trackerId, date: date) else {
            return // Запись не найдена, ничего не делаем
        }
        
        context.delete(record)
        try context.save()
    }
    
    /// Удаляет все записи для конкретного трекера
    func deleteRecords(for trackerId: UUID) throws {
        let records = try fetchRecords(for: trackerId)
        records.forEach { context.delete($0) }
        try context.save()
    }
    
    // MARK: - Conversion Helpers
    
    /// Конвертирует TrackerRecordCoreData в TrackerRecord
    func convertToRecord(_ recordCoreData: TrackerRecordCoreData) -> TrackerRecord? {
        guard let id = recordCoreData.id,
              let date = recordCoreData.date else {
            return nil
        }
        
        return TrackerRecord(id: id, date: date)
    }
    
    /// Конвертирует массив TrackerRecordCoreData в Set TrackerRecord
    func convertToRecords(_ recordsCoreData: [TrackerRecordCoreData]) -> Set<TrackerRecord> {
        return Set(recordsCoreData.compactMap { convertToRecord($0) })
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerRecordStoreDidUpdate()
    }
}


