import CoreData
import UIKit

protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreDidUpdate()
}

final class TrackerStore: NSObject {
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>?
    weak var delegate: TrackerStoreDelegate?
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
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
    
    func getFetchedTrackers() -> [TrackerCoreData] {
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
            delegate?.trackerStoreDidUpdate()
        } catch {
            print("Ошибка при выполнении fetch: \(error)")
        }
    }
    
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
    
    func fetchTrackers() throws -> [TrackerCoreData] {
        let request = TrackerCoreData.fetchRequest()
        return try context.fetch(request)
    }
    
    func fetchTracker(by id: UUID) throws -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }
    
    func fetchTrackers(by category: TrackerCategoryCoreData) throws -> [TrackerCoreData] {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        return try context.fetch(request)
    }
    
    func updateTracker(_ trackerCoreData: TrackerCoreData, with tracker: Tracker) throws {
        trackerCoreData.name = tracker.name
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.color = colorToHex(tracker.color)
        trackerCoreData.schedule = scheduleToString(tracker.schedule)
        
        try context.save()
    }
    
    func deleteTracker(_ trackerCoreData: TrackerCoreData) throws {
        context.delete(trackerCoreData)
        try context.save()
    }
    
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

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerStoreDidUpdate()
    }
}
