import SwiftUI
import SwiftData
import SharedModels

// MARK: - 투두 상세/편집 화면 (A1, A2)
public struct TodoDetailView: View {
    @Bindable var todo: TodoItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var showPrerequisitePicker = false
    @State private var showRecurrenceEditor = false

    public init(todo: TodoItem) {
        self.todo = todo
        _hasDueDate = State(initialValue: todo.dueDate != nil)
        _dueDate = State(initialValue: todo.dueDate ?? Date())
    }

    public var body: some View {
        Form {
            Section {
                TextField("할 일", text: $todo.title, axis: .vertical)
                    .font(SketchTheme.headline)
                TextField("메모", text: notesBinding, axis: .vertical)
                    .lineLimit(1...5)
                    .foregroundStyle(.secondary)
            }

            Section("마감") {
                Toggle("날짜 지정", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("마감일", selection: $dueDate, displayedComponents: [.date])
                }
            }

            // 반복 (B1)
            Section("반복") {
                Button {
                    showRecurrenceEditor = true
                } label: {
                    HStack {
                        Label("반복", systemImage: "repeat")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(todo.recurrence?.displayText ?? "안 함")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 연계형 투두 (A2)
            Section {
                ForEach(prerequisiteTodos) { prereq in
                    HStack {
                        Image(systemName: prereq.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(prereq.isCompleted ? .green : .secondary)
                        Text(prereq.title)
                        Spacer()
                    }
                }
                .onDelete(perform: removePrerequisites)

                Button {
                    showPrerequisitePicker = true
                } label: {
                    Label("선행 조건 추가", systemImage: "link")
                }
            } header: {
                Text("이 일을 하기 전에")
            } footer: {
                if todo.status == .locked {
                    Text("선행 조건이 완료되면 자동으로 활성화돼요")
                }
            }
        }
        .navigationTitle("할 일")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: hasDueDate) { _, on in todo.dueDate = on ? dueDate : nil }
        .onChange(of: dueDate) { _, d in if hasDueDate { todo.dueDate = d } }
        .sheet(isPresented: $showPrerequisitePicker) {
            PrerequisitePickerView(todo: todo)
        }
        .sheet(isPresented: $showRecurrenceEditor) {
            NavigationStack { RecurrenceEditorView(rule: recurrenceBinding) }
        }
    }

    private var notesBinding: Binding<String> {
        Binding(get: { todo.notes ?? "" }, set: { todo.notes = $0.isEmpty ? nil : $0 })
    }

    private var recurrenceBinding: Binding<RecurrenceRule?> {
        Binding(get: { todo.recurrence }, set: { todo.recurrence = $0 })
    }

    private var prerequisiteTodos: [TodoItem] {
        let ids = Set(todo.prerequisiteIDs)
        let descriptor = FetchDescriptor<TodoItem>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { ids.contains($0.id) }
    }

    private func removePrerequisites(at offsets: IndexSet) {
        let toRemove = offsets.map { prerequisiteTodos[$0].id }
        todo.prerequisiteIDs.removeAll { toRemove.contains($0) }
        // 남은 선행이 모두 완료(또는 없음)면 잠금 해제
        if todo.status == .locked && !todo.isCompleted {
            let remaining = prerequisiteTodos
            if remaining.allSatisfy(\.isCompleted) {
                todo.status = .available
            }
        }
    }
}

// MARK: - 선행 조건 선택 (사이클 방지)
struct PrerequisitePickerView: View {
    let todo: TodoItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var cycleAlert = false

    // 같은 공유방(또는 같은 개인 영역) + 자기 자신/이미 선행인 것 제외
    private var candidates: [TodoItem] {
        let spaceID = todo.space?.id
        let descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.title)])
        let all = (try? context.fetch(descriptor)) ?? []
        let existing = Set(todo.prerequisiteIDs)
        return all.filter {
            $0.id != todo.id &&
            !existing.contains($0.id) &&
            $0.space?.id == spaceID
        }
    }

    var body: some View {
        NavigationStack {
            List(candidates) { candidate in
                Button {
                    add(candidate)
                } label: {
                    HStack {
                        Text(candidate.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        if candidate.isCompleted {
                            Image(systemName: "checkmark").foregroundStyle(.green)
                        }
                    }
                }
            }
            .overlay {
                if candidates.isEmpty {
                    ContentUnavailableView("선택할 항목 없음", systemImage: "link")
                }
            }
            .navigationTitle("선행 조건")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
            }
            .alert("순환 참조", isPresented: $cycleAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("이 항목을 선행으로 추가하면 서로 의존하게 돼요. 추가할 수 없어요.")
            }
        }
    }

    private func add(_ candidate: TodoItem) {
        let all = (try? context.fetch(FetchDescriptor<TodoItem>())) ?? []
        let ok = ChainManager.addPrerequisite(candidate, to: todo, allTodos: all)
        if ok { dismiss() } else { cycleAlert = true }
    }
}

// MARK: - Preview (시각 검증 대체물)
#Preview("상세 - 잠김") {
    let container = try! ModelContainer(
        for: TodoItem.self, Space.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let todo = TodoItem(title: "요리하기")
    todo.notes = "재료 손질부터"
    todo.status = .locked
    todo.prerequisiteIDs = [UUID()]
    container.mainContext.insert(todo)
    return NavigationStack { TodoDetailView(todo: todo) }
        .modelContainer(container)
}
