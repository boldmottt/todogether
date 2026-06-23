import WidgetKit
import SwiftUI
import AppIntents
import SharedModels

// MARK: - 타임라인 엔트리
public struct TodoWidgetEntry: TimelineEntry {
    public let date: Date
    public let todos: [WidgetTodo]

    public init(date: Date, todos: [WidgetTodo]) {
        self.date = date
        self.todos = todos
    }
}

// MARK: - 타임라인 프로바이더
public struct TodoWidgetProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> TodoWidgetEntry {
        TodoWidgetEntry(date: .now, todos: [
            WidgetTodo(id: UUID(), title: "장보기", isCompleted: false),
            WidgetTodo(id: UUID(), title: "운동하기", isCompleted: false),
        ])
    }

    public func getSnapshot(in context: Context, completion: @escaping (TodoWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<TodoWidgetEntry>) -> Void) {
        let todos = SharedStore.load()
        let entry = TodoWidgetEntry(date: .now, todos: todos)
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - 인터랙티브 토글 AppIntent (iOS 17+)
public struct ToggleTodoIntent: AppIntent {
    public static var title: LocalizedStringResource = "투두 완료 토글"

    @Parameter(title: "Todo ID")
    public var todoID: String

    public init() {}
    public init(todoID: String) { self.todoID = todoID }

    public func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: todoID) {
            SharedStore.toggle(id: id)
        }
        return .result()
    }
}

// MARK: - 위젯 뷰 (Medium)
public struct TodoWidgetMediumView: View {
    let entry: TodoWidgetEntry

    public init(entry: TodoWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘 할 일")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if entry.todos.isEmpty {
                Text("할 일이 없어요 🎉")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(entry.todos.prefix(4)) { todo in
                    Button(intent: ToggleTodoIntent(todoID: todo.id.uuidString)) {
                        HStack(spacing: 8) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(todo.isCompleted ? .green : .secondary)
                            Text(todo.title)
                                .strikethrough(todo.isCompleted)
                                .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}
