import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 타임라인 엔트리
struct TodoWidgetEntry: TimelineEntry {
    let date: Date
    let todos: [WidgetTodo]
}

struct WidgetTodo: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
}

// MARK: - 타임라인 프로바이더
struct TodoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoWidgetEntry {
        TodoWidgetEntry(date: .now, todos: [
            WidgetTodo(id: UUID(), title: "장보기", isCompleted: false),
            WidgetTodo(id: UUID(), title: "운동하기", isCompleted: true),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoWidgetEntry>) -> Void) {
        let todos = SharedStore.loadTodosForWidget()  // App Group에서 읽기
        let entry = TodoWidgetEntry(date: .now, todos: todos)

        // 자정에 자동 갱신
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// MARK: - 인터랙티브 토글 AppIntent (iOS 17+)
struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "투두 완료 토글"

    @Parameter(title: "Todo ID")
    var todoID: String

    func perform() async throws -> some IntentResult {
        SharedStore.toggleTodo(id: UUID(uuidString: todoID)!)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - 위젯 뷰 (Medium)
struct TodoWidgetMediumView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘 할 일")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(entry.todos.prefix(4)) { todo in
                Button(intent: ToggleTodoIntent(todoID: todo.id.uuidString)) {
                    HStack {
                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(todo.isCompleted ? .green : .secondary)
                        Text(todo.title)
                            .strikethrough(todo.isCompleted)
                            .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

// MARK: - App Group 공유 저장소 (스텁)
enum SharedStore {
    static let groupID = "group.com.yourteam.todogether"

    static func loadTodosForWidget() -> [WidgetTodo] {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("widget_todos.json"),
              let data = try? Data(contentsOf: url)
        else { return [] }
        return (try? JSONDecoder().decode([WidgetTodo].self, from: data)) ?? []
    }

    static func toggleTodo(id: UUID) {
        var todos = loadTodosForWidget()
        if let idx = todos.firstIndex(where: { $0.id == id }) {
            todos[idx].isCompleted.toggle()
            saveTodos(todos)
        }
    }

    private static func saveTodos(_ todos: [WidgetTodo]) {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("widget_todos.json"),
              let data = try? JSONEncoder().encode(todos)
        else { return }
        try? data.write(to: url)
    }
}
