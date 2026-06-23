import Foundation
import WidgetKit
import SharedModels

// MARK: - App Group 공유 저장소
// 앱과 위젯 Extension이 같은 App Group ID를 사용해야 함
public enum SharedStore {
    public static let appGroupID = "group.com.yourteam.todogether"  // 실제 값으로 교체

    private static var storeURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("widget_todos.json")
    }

    public static func save(_ todos: [WidgetTodo]) {
        guard let url = storeURL,
              let data = try? JSONEncoder().encode(todos) else { return }
        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func load() -> [WidgetTodo] {
        guard let url = storeURL,
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([WidgetTodo].self, from: data)) ?? []
    }

    public static func toggle(id: UUID) {
        var todos = load()
        guard let idx = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[idx].isCompleted.toggle()
        save(todos)
    }

    /// 앱에서 TodoItem 변경 시 호출 — 위젯용 경량 모델로 변환 후 저장
    public static func sync(from todos: [TodoItem]) {
        let widgetTodos = todos
            .filter { !$0.isCompleted && $0.status == .available }
            .prefix(10)
            .map { WidgetTodo(id: $0.id, title: $0.title, isCompleted: $0.isCompleted, dueDate: $0.dueDate) }
        save(Array(widgetTodos))
    }
}
