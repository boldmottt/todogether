import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable {
    case daily, weekly, monthly, yearly
    case afterCompletion  // 완료 후 N일 (습관형)
}

struct RecurrenceRule: Codable {
    var frequency: RecurrenceFrequency
    var interval: Int = 1           // 2 = "2주마다"
    var weekdays: [Int]?            // 1=일 ~ 7=토, weekly일 때
    var monthDay: Int?              // 1~31, monthly일 때
    var endDate: Date?

    /// 기준 날짜로부터 다음 발생일 계산
    func nextOccurrence(after date: Date) -> Date? {
        var components = DateComponents()
        switch frequency {
        case .daily:
            components.day = interval
        case .weekly:
            components.weekOfYear = interval
        case .monthly:
            components.month = interval
        case .yearly:
            components.year = interval
        case .afterCompletion:
            components.day = interval  // 완료 시점(date)에서 interval일 후
        }

        let next = Calendar.current.date(byAdding: components, to: date)
        if let endDate, let next, next > endDate { return nil }
        return next
    }
}

// MARK: - SwiftData 모델 예시
@Model
final class TodoItem {
    var title: String
    var dueDate: Date?
    var isCompleted: Bool = false
    var recurrenceData: Data?  // RecurrenceRule을 JSON으로 인코딩해서 저장

    var recurrence: RecurrenceRule? {
        get {
            guard let data = recurrenceData else { return nil }
            return try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        set {
            recurrenceData = try? JSONEncoder().encode(newValue)
        }
    }

    init(title: String, dueDate: Date? = nil) {
        self.title = title
        self.dueDate = dueDate
    }

    /// 완료 처리 + 반복이면 다음 항목 생성
    func complete() -> TodoItem? {
        isCompleted = true
        guard let rule = recurrence else { return nil }

        let baseDate: Date
        switch rule.frequency {
        case .afterCompletion:
            baseDate = Date()
        default:
            baseDate = dueDate ?? Date()
        }

        guard let nextDate = rule.nextOccurrence(after: baseDate) else { return nil }

        let next = TodoItem(title: title, dueDate: nextDate)
        next.recurrence = rule
        return next
    }
}
