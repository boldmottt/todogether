import Foundation
import SwiftData

// MARK: - Space (공유방)
@Model
final class Space {
    var id: UUID
    var name: String
    var colorHex: String       // 피드뷰에서 공유방 색상 코딩용
    var cloudKitShareID: String?  // CKShare.recordID.recordName
    @Relationship(deleteRule: .cascade) var todos: [TodoItem] = []

    init(name: String, colorHex: String = "#5E5CE6") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
    }
}

// MARK: - TodoItem (통합)
@Model
final class TodoItem {
    var id: UUID
    var title: String
    var notes: String?
    var dueDate: Date?
    var isCompleted: Bool = false
    var completedAt: Date?
    var status: TodoStatus         // locked / available / completed
    var assigneeID: String?        // iCloud User Record ID

    // 연계형: CloudKit sync 안정성을 위해 관계 대신 UUID 직접 참조
    var prerequisiteIDs: [UUID] = []

    // 반복: Codable 구조체를 Data로 저장
    var recurrenceData: Data?

    // 템플릿 추적
    var templateID: UUID?

    var space: Space?

    var recurrence: RecurrenceRule? {
        get { try? JSONDecoder().decode(RecurrenceRule.self, from: recurrenceData ?? Data()) }
        set { recurrenceData = try? JSONEncoder().encode(newValue) }
    }

    init(title: String, space: Space? = nil) {
        self.id = UUID()
        self.title = title
        self.space = space
        self.status = .available
    }
}

// MARK: - 반복 규칙 (02-recurring 동일)
enum RecurrenceFrequency: String, Codable {
    case daily, weekly, monthly, yearly, afterCompletion
}

struct RecurrenceRule: Codable {
    var frequency: RecurrenceFrequency
    var interval: Int = 1
    var weekdays: [Int]?
    var monthDay: Int?
    var endDate: Date?

    func nextOccurrence(after date: Date) -> Date? {
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

// MARK: - 투두 상태 (03-chained-todos 동일)
enum TodoStatus: String, Codable {
    case locked, available, completed
}

// MARK: - 템플릿 (04-templates 동일)
@Model
final class TodoTemplate {
    var id: UUID
    var name: String
    var itemsData: Data

    var items: [TemplateItem] {
        get { (try? JSONDecoder().decode([TemplateItem].self, from: itemsData)) ?? [] }
        set { itemsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(name: String, items: [TemplateItem] = []) {
        self.id = UUID()
        self.name = name
        self.itemsData = (try? JSONEncoder().encode(items)) ?? Data()
    }
}

struct TemplateItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var relativeDeadlineDays: Int?
    var assigneeRole: String?
    var prerequisiteIndex: Int?
}

// MARK: - ModelContainer 설정
extension ModelContainer {
    static func makeShared() throws -> ModelContainer {
        let schema = Schema([Space.self, TodoItem.self, TodoTemplate.self])
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic  // CloudKit sync 활성화
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}
