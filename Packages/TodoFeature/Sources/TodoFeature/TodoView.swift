import SwiftUI
import SwiftData
import SharedModels

// MARK: - 투두 리스트 뷰
public struct TodoListView: View {
    let space: Space?
    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false

    public init(space: Space? = nil) {
        self.space = space
    }

    public var body: some View {
        TodoListContent(space: space)
            .toolbar {
                Button("추가", systemImage: "plus") { showAddSheet = true }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTodoView(space: space)
            }
    }
}

// MARK: - 리스트 내용 (Query를 위해 분리)
private struct TodoListContent: View {
    let space: Space?
    @Query private var todos: [TodoItem]

    init(space: Space?) {
        self.space = space
        // space가 있으면 해당 공유방 투두만, 없으면 전체
        if let space {
            _todos = Query(
                filter: #Predicate { $0.space?.id == space.id },
                sort: \.dueDate
            )
        } else {
            _todos = Query(sort: \TodoItem.dueDate)
        }
    }

    var body: some View {
        List {
            ForEach(todos) { todo in
                TodoRowView(todo: todo)
            }
        }
    }
}

// MARK: - 투두 행
public struct TodoRowView: View {
    @Bindable var todo: TodoItem
    @Environment(\.modelContext) private var context

    public init(todo: TodoItem) {
        self.todo = todo
    }

    public var body: some View {
        HStack {
            Button {
                ChainManager.complete(todo, context: context)
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : statusIcon)
                    .foregroundStyle(statusColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.status == .locked ? .secondary : .primary)
                if let due = todo.dueDate {
                    Text(due, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusIcon: String {
        switch todo.status {
        case .locked: "lock.circle"
        case .available: "circle"
        case .completed: "checkmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch todo.status {
        case .locked: .secondary
        case .available: .primary
        case .completed: .green
        }
    }
}

// MARK: - 투두 추가
struct AddTodoView: View {
    let space: Space?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dueDate: Date?
    @State private var hasDueDate = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("할 일", text: $title)
                Toggle("날짜 지정", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("날짜", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: .date)
                }
            }
            .navigationTitle("새 할 일")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") { add() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func add() {
        let todo = TodoItem(title: title.trimmingCharacters(in: .whitespaces), space: space)
        todo.dueDate = hasDueDate ? dueDate : nil
        context.insert(todo)
        dismiss()
    }
}

// MARK: - 체인 관리
public enum ChainManager {
    public static func complete(_ todo: TodoItem, context: ModelContext) {
        guard todo.status == .available else { return }
        todo.isCompleted = true
        todo.completedAt = Date()
        todo.status = .completed

        // 반복이면 다음 투두 생성
        if let rule = todo.recurrence {
            let base: Date = rule.frequency == .afterCompletion ? Date() : (todo.dueDate ?? Date())
            if let nextDate = rule.nextOccurrence(after: base) {
                let next = TodoItem(title: todo.title, space: todo.space)
                next.dueDate = nextDate
                next.recurrence = rule
                next.templateID = todo.templateID
                context.insert(next)
            }
        }

        // 후속 투두 잠금 해제
        unlockDependents(of: todo, context: context)
    }

    private static func unlockDependents(of completed: TodoItem, context: ModelContext) {
        let completedID = completed.id
        let descriptor = FetchDescriptor<TodoItem>(
            filter: #Predicate { $0.status == .locked }
        )
        guard let locked = try? context.fetch(descriptor) else { return }

        // 완료된 항목 ID 집합
        let doneDescriptor = FetchDescriptor<TodoItem>(
            filter: #Predicate { $0.isCompleted == true }
        )
        let doneIDs = Set((try? context.fetch(doneDescriptor))?.map(\.id) ?? [])
        let allDone = doneIDs.union([completedID])

        for todo in locked where todo.prerequisiteIDs.allSatisfy({ allDone.contains($0) }) {
            todo.status = .available
        }
    }
}
