import Foundation

protocol StatisticsServiceDelegate: AnyObject {
    func statisticsDidUpdate()
}

final class StatisticsService {
    
    // MARK: - Properties
    static let shared = StatisticsService()
    
    private let recordStore: TrackerRecordStore
    weak var delegate: StatisticsServiceDelegate?
    
    // MARK: - Init
    init(recordStore: TrackerRecordStore = TrackerRecordStore()) {
        self.recordStore = recordStore
    }
    
    // MARK: - Public Methods
    func getFinishedTrackersCount() -> Int {
        do {
            let records = try recordStore.fetchRecords()
            let uniqueTrackerIds = Set(records.compactMap { $0.tracker?.id })
            return uniqueTrackerIds.count
        } catch {
            return 0
        }
    }
    
    func notifyUpdate() {
        delegate?.statisticsDidUpdate()
    }
}

