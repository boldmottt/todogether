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
        var components = DateComponents()
        switch frequency {
        case .daily, .afterCompletion: components.day = interval
        case .weekly: components.weekOfYear = interval
        case .monthly: components.month = interval
        case .yearly: components.year = interval
        }
        let next = Calendar.current.date(byAdding: components, to: date)
        if let endDate, let next, next > endDate { return nil }
        return next
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
