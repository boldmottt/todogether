import Foundation
import SwiftData

// MARK: - Space (공유방)
@Model
public final class Space {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var cloudKitShareID: String?
    @Relationship(deleteRule: .cascade) public var todos: [TodoItem] = []

    public init(name: String, colorHex: String = "#5E5CE6") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
    }
}

// MARK: - TodoItem
@Model
public final class TodoItem {
    public var id: UUID
    public var title: String
    public var notes: String?
    public var dueDate: Date?
    public var isCompleted: Bool = false
    public var completedAt: Date?
    public var status: TodoStatus
    public var assigneeID: String?
    public var prerequisiteIDs: [UUID] = []
    public var recurrenceData: Data?
    public var templateID: UUID?
    public var space: Space?

    public var recurrence: RecurrenceRule? {
        get { try? JSONDecoder().decode(RecurrenceRule.self, from: recurrenceData ?? Data()) }
        set { recurrenceData = try? JSONEncoder().encode(newValue) }
    }

    public init(title: String, space: Space? = nil) {
        self.id = UUID()
        self.title = title
        self.space = space
        self.status = .available
    }
}

// MARK: - TodoTemplate
@Model
public final class TodoTemplate {
    public var id: UUID
    public var name: String
    public var itemsData: Data

    public var items: [TemplateItem] {
        get { (try? JSONDecoder().decode([TemplateItem].self, from: itemsData)) ?? [] }
        set { itemsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    public init(name: String, items: [TemplateItem] = []) {
        self.id = UUID()
        self.name = name
        self.itemsData = (try? JSONEncoder().encode(items)) ?? Data()
    }
}

// MARK: - Value Types
public enum TodoStatus: String, Codable {
    case locked, available, completed
}

public enum RecurrenceFrequency: String, Codable {
    case daily, weekly, monthly, yearly, afterCompletion
}

public struct RecurrenceRule: Codable {
    public var frequency: RecurrenceFrequency
    public var interval: Int = 1
    public var weekdays: [Int]?
    public var monthDay: Int?
    public var endDate: Date?

    public init(frequency: RecurrenceFrequency, interval: Int = 1) {
        self.frequency = frequency
        self.interval = interval
    }

    public func nextOccurrence(after date: Date) -> Date? {
        let cal = Calendar.current
        var next: Date?
        switch frequency {
        case .daily, .afterCompletion:
            next = cal.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            if let weekdays, !weekdays.isEmpty {
                // Find the next matching weekday within future weeks
                let sorted = weekdays.sorted()
                var candidate = cal.date(byAdding: .day, value: 1, to: date)!
                for _ in 0..<(7 * interval + 7) {
                    let wd = cal.component(.weekday, from: candidate)
                    if sorted.contains(wd) {
                        // Must be at least `interval` weeks after date's week
                        let weeksApart = cal.dateComponents([.weekOfYear], from: date, to: candidate).weekOfYear ?? 0
                        if weeksApart >= interval {
                            next = candidate
                            break
                        }
                    }
                    candidate = cal.date(byAdding: .day, value: 1, to: candidate)!
                }
                if next == nil {
                    next = cal.date(byAdding: .weekOfYear, value: interval, to: date)
                }
            } else {
                next = cal.date(byAdding: .weekOfYear, value: interval, to: date)
            }
        case .monthly:
            if let monthDay {
                // Advance by `interval` months, then set the target day
                var comps = cal.dateComponents([.year, .month], from: date)
                comps.month = (comps.month ?? 1) + interval
                comps.day = monthDay
                comps.hour = cal.component(.hour, from: date)
                comps.minute = cal.component(.minute, from: date)
                next = cal.date(from: comps)
            } else {
                next = cal.date(byAdding: .month, value: interval, to: date)
            }
        case .yearly:
            next = cal.date(byAdding: .year, value: interval, to: date)
        }
        if let endDate, let next, next > endDate { return nil }
        return next
    }

    /// 사람이 읽는 요약 문구 (TodoFeature·RecurringFeature 공용)
    public var displayText: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "매일" : "\(interval)일마다"
        case .weekly:
            let base = interval == 1 ? "매주" : "\(interval)주마다"
            if let weekdays, !weekdays.isEmpty {
                let names = weekdays.sorted().map { RecurrenceRule.weekdayShortName($0) }.joined(separator: "·")
                return "\(base) \(names)"
            }
            return base
        case .monthly:
            let base = interval == 1 ? "매월" : "\(interval)개월마다"
            if let monthDay { return "\(base) \(monthDay)일" }
            return base
        case .yearly:
            return interval == 1 ? "매년" : "\(interval)년마다"
        case .afterCompletion:
            return "완료 후 \(interval)일"
        }
    }

    /// 1=일 ... 7=토
    public static func weekdayShortName(_ weekday: Int) -> String {
        let names = ["", "일", "월", "화", "수", "목", "금", "토"]
        guard names.indices.contains(weekday) else { return "" }
        return names[weekday]
    }
}

public struct TemplateItem: Codable, Identifiable {
    public var id: UUID = UUID()
    public var title: String
    public var relativeDeadlineDays: Int?
    public var assigneeRole: String?
    public var prerequisiteIndex: Int?

    public init(title: String) {
        self.title = title
    }
}

// MARK: - Reaction (완료 이모지 반응)
@Model
public final class Reaction {
    public var id: UUID
    public var todoID: UUID       // TodoItem과 관계 대신 UUID 직접 참조
    public var authorID: String   // iCloud User Record ID
    public var authorName: String // 표시용 이름 캐시
    public var emoji: String      // "👍"
    public var createdAt: Date

    public init(todoID: UUID, authorID: String, authorName: String, emoji: String) {
        self.id = UUID()
        self.todoID = todoID
        self.authorID = authorID
        self.authorName = authorName
        self.emoji = emoji
        self.createdAt = Date()
    }
}

public extension Reaction {
    static let availableEmojis = ["👍", "❤️", "🎉", "💪", "😂", "🙏"]
}

// MARK: - Widget 경량 모델 (App Group 공유용)
public struct WidgetTodo: Identifiable, Codable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var dueDate: Date?

    public init(id: UUID, title: String, isCompleted: Bool, dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
    }
}

// MARK: - ModelContainer
public extension ModelContainer {
    static func makeShared() throws -> ModelContainer {
        let schema = Schema([Space.self, TodoItem.self, TodoTemplate.self, Reaction.self])
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}
