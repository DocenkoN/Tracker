import CoreData
import UIKit

/// Протокол делегата для получения обновлений от TrackerStore
protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreDidUpdate()
}

/// Store для работы с TrackerCoreData Entity
/// Абстрагирует приложение от Core Data
final class TrackerStore: NSObject {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>?
    weak var delegate: TrackerStoreDelegate?
    
    // MARK: - Initialization
    
    /// Constructor Injection - передача контекста через init
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
    // MARK: - NSFetchedResultsController Setup
    
    private func setupFetchedResultsController() {
        let request = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
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
    
    /// Получает все трекеры через NSFetchedResultsController
    func getFetchedTrackers() -> [TrackerCoreData] {
        return fetchedResultsController?.fetchedObjects ?? []
    }
    
    /// Обновляет предикат для фильтрации трекеров
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
            delegate?.trackerStoreDidUpdate()
        } catch {
            print("Ошибка при выполнении fetch: \(error)")
        }
    }
    
    // MARK: - Create
    
    /// Создает новый трекер в Core Data
    func createTracker(from tracker: Tracker, category: TrackerCategoryCoreData) throws -> TrackerCoreData {
        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.color = colorToHex(tracker.color)
        trackerCoreData.schedule = scheduleToString(tracker.schedule)
        trackerCoreData.category = category
        
        try context.save()
        return trackerCoreData
    }
    
    // MARK: - Read
    
    /// Получает все трекеры
    func fetchTrackers() throws -> [TrackerCoreData] {
        let request = TrackerCoreData.fetchRequest()
        return try context.fetch(request)
    }
    
    /// Получает трекер по ID
    func fetchTracker(by id: UUID) throws -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }
    
    /// Получает трекеры по категории
    func fetchTrackers(by category: TrackerCategoryCoreData) throws -> [TrackerCoreData] {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        return try context.fetch(request)
    }
    
    // MARK: - Update
    
    /// Обновляет существующий трекер
    func updateTracker(_ trackerCoreData: TrackerCoreData, with tracker: Tracker) throws {
        trackerCoreData.name = tracker.name
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.color = colorToHex(tracker.color)
        trackerCoreData.schedule = scheduleToString(tracker.schedule)
        
        try context.save()
    }
    
    // MARK: - Delete
    
    /// Удаляет трекер
    func deleteTracker(_ trackerCoreData: TrackerCoreData) throws {
        context.delete(trackerCoreData)
        try context.save()
    }
    
    // MARK: - Conversion Helpers
    
    /// Конвертирует TrackerCoreData в Tracker
    func convertToTracker(_ trackerCoreData: TrackerCoreData) -> Tracker? {
        guard let id = trackerCoreData.id,
              let name = trackerCoreData.name,
              let emoji = trackerCoreData.emoji,
              let colorHex = trackerCoreData.color else {
            return nil
        }
        
        let color = hexToColor(colorHex)
        let schedule = stringToSchedule(trackerCoreData.schedule)
        
        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
    }
    
    // MARK: - Private Helpers
    
    private func colorToHex(_ color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
    
    private func hexToColor(_ hex: String) -> UIColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    private func scheduleToString(_ schedule: [WeekDay]) -> String {
        let numbers = schedule.map { String($0.rawValue) }
        return numbers.joined(separator: ",")
    }
    
    private func stringToSchedule(_ string: String?) -> [WeekDay] {
        guard let string = string, !string.isEmpty else {
            return []
        }
        
        return string.components(separatedBy: ",")
            .compactMap { Int($0) }
            .compactMap { WeekDay(rawValue: $0) }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerStoreDidUpdate()
    }
}
