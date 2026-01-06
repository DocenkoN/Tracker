import Foundation

struct StatisticsData {
    let bestPeriod: Int
    let idealDays: Int
    let completedTrackers: Int
    let averageValue: Double
}

final class StatisticsCalculator {
    
    static func calculateStatistics(
        records: Set<TrackerRecord>,
        trackers: [Tracker]
    ) -> StatisticsData {
        let completedTrackers = records.count
        
        // Группируем записи по датам
        let recordsByDate = Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.date)
        }
        
        // Получаем все уникальные даты
        let allDates = Set(records.map { Calendar.current.startOfDay(for: $0.date) })
        
        // Рассчитываем лучший период (максимальная серия дней подряд)
        let bestPeriod = calculateBestPeriod(dates: allDates)
        
        // Рассчитываем идеальные дни (дни, когда выполнены все трекеры)
        let idealDays = calculateIdealDays(
            recordsByDate: recordsByDate,
            trackers: trackers
        )
        
        // Рассчитываем среднее значение
        let averageValue = calculateAverageValue(recordsByDate: recordsByDate)
        
        return StatisticsData(
            bestPeriod: bestPeriod,
            idealDays: idealDays,
            completedTrackers: completedTrackers,
            averageValue: averageValue
        )
    }
    
    private static func calculateBestPeriod(dates: Set<Date>) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let sortedDates = dates.sorted()
        var maxPeriod = 1
        var currentPeriod = 1
        
        for i in 1..<sortedDates.count {
            let daysBetween = Calendar.current.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysBetween == 1 {
                currentPeriod += 1
                maxPeriod = max(maxPeriod, currentPeriod)
            } else {
                currentPeriod = 1
            }
        }
        
        return maxPeriod
    }
    
    private static func calculateIdealDays(
        recordsByDate: [Date: [TrackerRecord]],
        trackers: [Tracker]
    ) -> Int {
        guard !trackers.isEmpty else { return 0 }
        
        var idealDaysCount = 0
        
        for (date, records) in recordsByDate {
            // Получаем уникальные ID трекеров, выполненных в этот день
            let completedTrackerIds = Set(records.map { $0.id })
            
            // Проверяем, какие трекеры должны быть выполнены в этот день
            let calendar = Calendar.current
            let weekDay = calendar.component(.weekday, from: date)
            
            let currentWeekDay: WeekDay
            switch weekDay {
            case 1: currentWeekDay = .sunday
            case 2: currentWeekDay = .monday
            case 3: currentWeekDay = .tuesday
            case 4: currentWeekDay = .wednesday
            case 5: currentWeekDay = .thursday
            case 6: currentWeekDay = .friday
            case 7: currentWeekDay = .saturday
            default: currentWeekDay = .monday
            }
            
            // Фильтруем трекеры, которые должны быть выполнены в этот день
            let trackersForDate = trackers.filter { tracker in
                if tracker.schedule.isEmpty {
                    return true
                }
                return tracker.schedule.contains(currentWeekDay)
            }
            
            // Проверяем, выполнены ли все трекеры для этого дня
            let trackersForDateIds = Set(trackersForDate.map { $0.id })
            if !trackersForDateIds.isEmpty && trackersForDateIds.isSubset(of: completedTrackerIds) {
                idealDaysCount += 1
            }
        }
        
        return idealDaysCount
    }
    
    private static func calculateAverageValue(recordsByDate: [Date: [TrackerRecord]]) -> Double {
        guard !recordsByDate.isEmpty else { return 0 }
        
        let totalRecords = recordsByDate.values.reduce(0) { $0 + $1.count }
        let numberOfDays = recordsByDate.count
        
        return Double(totalRecords) / Double(numberOfDays)
    }
}

