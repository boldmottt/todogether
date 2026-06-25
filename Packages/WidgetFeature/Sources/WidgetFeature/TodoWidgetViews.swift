import WidgetKit
import SwiftUI
import AppIntents
import SharedModels

// MARK: - 공용 투두 행 (토글 버튼 + 딥링크)
/// 체크마크만 인터랙티브 토글 버튼이고, 제목은 Link로 해당 투두 딥링크를 건다.
/// (Button과 row-level widgetURL을 겹치면 탭 충돌 + widgetURL은 위젯당 1개만
///  유효하므로, 다중 행에서는 Link로 per-row 내비게이션을 처리한다.)
struct TodoRow: View {
    let todo: WidgetTodo

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: ToggleTodoIntent(todoID: todo.id.uuidString)) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? SketchTheme.Color.ink : .secondary)
            }
            .buttonStyle(.plain)

            if let link = WidgetDeepLink.url(for: todo.id) {
                Link(destination: link) {
                    rowLabel
                }
            } else {
                rowLabel
            }
        }
    }

    private var rowLabel: some View {
        HStack(spacing: 0) {
            Text(todo.title)
                .strikethrough(todo.isCompleted)
                .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - 위젯 뷰 (Small)
/// 가장 급한 투두 한 개 + 완료 토글. 전체 영역에 해당 투두 딥링크.
public struct TodoWidgetSmallView: View {
    let entry: TodoWidgetEntry

    public init(entry: TodoWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘 할 일")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            if let todo = entry.todos.first {
                Spacer(minLength: 0)
                Button(intent: ToggleTodoIntent(todoID: todo.id.uuidString)) {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(todo.isCompleted ? SketchTheme.Color.ink : SketchTheme.Color.softInk)
                }
                .buttonStyle(.plain)

                Text(todo.title)
                    .font(.headline)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                if let due = todo.dueDate {
                    Text(due, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                Text("할 일이 없어요 🎉")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        // 첫 투두가 있으면 그 투두로, 없으면 홈으로 이동
        .widgetURL(entry.todos.first.map { WidgetDeepLink.url(for: $0.id) } ?? WidgetDeepLink.home())
    }
}

// MARK: - 위젯 뷰 (Large)
/// 최대 8개 투두 목록. 각 행에 토글 + 딥링크.
public struct TodoWidgetLargeView: View {
    let entry: TodoWidgetEntry

    public init(entry: TodoWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘 할 일")
                .font(.headline)
                .foregroundStyle(.primary)

            if entry.todos.isEmpty {
                Text("할 일이 없어요 🎉")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(entry.todos.prefix(8)) { todo in
                    TodoRow(todo: todo)
                    Divider()
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

// MARK: - 패밀리 분기 엔트리 뷰
public struct TodoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodoWidgetEntry

    public init(entry: TodoWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            TodoWidgetSmallView(entry: entry)
        case .systemLarge:
            TodoWidgetLargeView(entry: entry)
        default: // .systemMedium 등
            TodoWidgetMediumView(entry: entry)
        }
    }
}

// MARK: - 위젯 정의
public struct TodogetherWidget: Widget {
    public let kind = "TodogetherWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoWidgetProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Todogether 할 일")
        .description("오늘의 할 일을 확인하고 바로 완료 처리하세요.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 위젯 번들
public struct TodogetherWidgetBundle: WidgetBundle {
    public init() {}

    public var body: some Widget {
        TodogetherWidget()
    }
}

// MARK: - 프리뷰
#if DEBUG
private let sampleTodos: [WidgetTodo] = [
    WidgetTodo(id: UUID(), title: "장보기", isCompleted: false, dueDate: .now),
    WidgetTodo(id: UUID(), title: "운동하기", isCompleted: false, dueDate: .now.addingTimeInterval(3600)),
    WidgetTodo(id: UUID(), title: "이메일 답장", isCompleted: true),
    WidgetTodo(id: UUID(), title: "책 읽기", isCompleted: false),
    WidgetTodo(id: UUID(), title: "청소하기", isCompleted: false),
    WidgetTodo(id: UUID(), title: "물 주기", isCompleted: false),
    WidgetTodo(id: UUID(), title: "산책", isCompleted: false),
    WidgetTodo(id: UUID(), title: "일기 쓰기", isCompleted: false),
    WidgetTodo(id: UUID(), title: "넘치는 항목", isCompleted: false),
]

private let sampleEntry = TodoWidgetEntry(date: .now, todos: sampleTodos)

#Preview("Small", as: .systemSmall) {
    TodogetherWidget()
} timeline: {
    sampleEntry
    TodoWidgetEntry(date: .now, todos: [])
}

#Preview("Medium", as: .systemMedium) {
    TodogetherWidget()
} timeline: {
    sampleEntry
}

#Preview("Large", as: .systemLarge) {
    TodogetherWidget()
} timeline: {
    sampleEntry
}
#endif
