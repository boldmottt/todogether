import Foundation
import SwiftData

struct TemplateItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var relativeDeadlineDays: Int?  // 기준일 +N일
    var assigneeRole: String?       // "me" | "any"
    var prerequisiteIndex: Int?     // items 배열 내 선행 항목 인덱스
}

@Model
final class TodoTemplate {
    var id: UUID
    var name: String
    var itemsData: Data  // [TemplateItem] JSON

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

// MARK: - 인스턴스화
extension TodoTemplate {
    /// 기준일을 받아 TodoItem 배열 생성 (체인 연결 포함)
    func instantiate(startDate: Date = Date()) -> [ChainedTodo] {
        var created: [ChainedTodo] = []

        for (index, item) in items.enumerated() {
            let prereqs: [ChainedTodo]
            if let prereqIdx = item.prerequisiteIndex, prereqIdx < created.count {
                prereqs = [created[prereqIdx]]
            } else {
                prereqs = []
            }

            let todo = ChainedTodo(title: item.title, prerequisites: prereqs)

            // relativeDeadline이 있으면 dueDate 계산 (ChainedTodo에 dueDate 추가 필요)
            // todo.dueDate = Calendar.current.date(byAdding: .day, value: days, to: startDate)

            created.append(todo)
            _ = index
        }

        return created
    }
}
