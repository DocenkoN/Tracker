import Foundation

enum TrackerFilter: CaseIterable {
    case all
    case today
    case completed
    case notCompleted
    
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("All trackers", comment: "All trackers filter")
        case .today:
            return NSLocalizedString("Trackers for today", comment: "Trackers for today filter")
        case .completed:
            return NSLocalizedString("Completed", comment: "Completed filter")
        case .notCompleted:
            return NSLocalizedString("Not completed", comment: "Not completed filter")
        }
    }
}

