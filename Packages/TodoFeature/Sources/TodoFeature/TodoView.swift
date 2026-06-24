import SwiftUI
import SwiftData
import SharedModels
import NotificationFeature

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
            .navigationDestination(for: TodoItem.self) { todo in
                TodoDetailView(todo: todo)
            }
    }
}

// MARK: - 리스트 내용 (Query를 위해 분리)
private struct TodoListContent: View {
    let space: Space?
    @Environment(\.currentUser) private var currentUser
    @Environment(\.modelContext) private var context
    @Query private var todos: [TodoItem]
    @State private var hideCompleted = false
    @State private var pendingUndo: TodoSnapshot?
    @State private var showUndo = false

    init(space: Space?) {
        self.space = space
        // #Predicate에서 옵셔널 관계 traverse($0.space?.id)는 SwiftData에서 불안정 →
        // 정렬만 해서 전체를 가져온 뒤 공유방 필터는 메모리에서 처리한다.
        _todos = Query(sort: \TodoItem.dueDate)
    }

    // 현재 화면 범위(개인 / 특정 공유방)에 해당하는 투두만
    private var scoped: [TodoItem] {
        todos.filter { $0.space?.id == space?.id }
    }

    // A4: 활성/완료 분리. 완료는 최근 7일치만.
    private var activeTodos: [TodoItem] {
        scoped.filter { !$0.isCompleted }
    }
    private var recentCompleted: [TodoItem] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        return scoped
            .filter { $0.isCompleted && ($0.completedAt ?? .distantPast) >= weekAgo }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        List {
            Section {
                ForEach(activeTodos) { todo in
                    row(todo)
                        .swipeActions(edge: .leading) {
                            if todo.status == .available {
                                Button {
                                    ChainManager.complete(todo, context: context)
                                } label: { Label("완료", systemImage: "checkmark") }
                                .tint(.green)
                            }
                            // Donetick "claiming": 공유방 미배정 투두 → "내가 할게"
                            if isClaimable(todo) {
                                Button {
                                    claim(todo)
                                } label: { Label("내가 할게", systemImage: "person.badge.plus") }
                                .tint(.blue)
                            }
                            // E2: 콕 찌르기 — 다른 사람이 담당한 투두에만 (자기 자신 방지)
                            if todo.space != nil && todo.assigneeID != nil
                                && todo.assigneeID != currentUser.id {
                                Button {
                                    nudge(todo)
                                } label: { Label("콕!", systemImage: "hand.point.up.left.fill") }
                                .tint(.orange)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(todo)
                            } label: { Label("삭제", systemImage: "trash") }
                        }
                }
            } header: {
                if activeTodos.isEmpty && recentCompleted.isEmpty {
                    EmptyView()
                }
            }

            if !hideCompleted && !recentCompleted.isEmpty {
                Section("완료됨 · 최근 7일") {
                    ForEach(recentCompleted) { todo in
                        row(todo)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { delete(todo) } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .overlay {
            if activeTodos.isEmpty && recentCompleted.isEmpty {
                ContentUnavailableView {
                    Label(space == nil ? "오늘 할 일이 없어요" : "\(space?.name ?? "")방의 첫 할 일을 추가해봐요",
                          systemImage: "checklist")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Toggle("완료 숨기기", isOn: $hideCompleted)
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
            }
        }
        .overlay(alignment: .bottom) {
            if showUndo {
                UndoToast(message: "삭제됨") { undoDelete() }
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func row(_ todo: TodoItem) -> some View {
        NavigationLink(value: todo) {
            ReactableTodoRow(
                todo: todo,
                currentUserID: currentUser.id,
                currentUserName: currentUser.name
            )
        }
    }

    // A3: 삭제 + Undo
    private func delete(_ todo: TodoItem) {
        let snap = TodoSnapshot(from: todo)
        pendingUndo = snap
        context.delete(todo)
        withAnimation { showUndo = true }
        Task {
            try? await Task.sleep(for: .seconds(5))
            // 그 사이 다른 삭제/실행취소가 일어났으면 건드리지 않는다 (레이스 방지)
            if pendingUndo?.id == snap.id {
                withAnimation { showUndo = false }
                pendingUndo = nil
            }
        }
    }

    private func undoDelete() {
        guard let snap = pendingUndo else { return }
        let restored = snap.makeTodo(space: space)
        context.insert(restored)
        pendingUndo = nil
        withAnimation { showUndo = false }
    }

    // E2: 콕 찌르기 (1일 1회 제한은 NudgeStore가 강제)
    private func nudge(_ todo: TodoItem) {
        NotificationManager.shared.sendNudge(
            todoID: todo.id,
            todoTitle: todo.title,
            senderID: currentUser.id,
            senderName: currentUser.name,
            spaceID: todo.space?.id,
            store: Self.nudgeStore
        )
    }

    private func isClaimable(_ todo: TodoItem) -> Bool {
        todo.space != nil && todo.assigneeID == nil && !todo.isCompleted
    }

    // Donetick 클레이밍: 미배정 공유방 투두를 현재 사용자가 담당
    private func claim(_ todo: TodoItem) {
        // Race-condition guard: another user may have claimed between render and tap
        guard todo.assigneeID == nil else { return }
        todo.assigneeID = currentUser.id
        try? context.save()
    }

    private static let nudgeStore = NudgeStore()
}

// MARK: - 삭제 복원용 스냅샷
private struct TodoSnapshot {
    let id: UUID            // 원래 식별자 보존 → 다른 투두의 선행 참조가 깨지지 않음
    let title: String
    let notes: String?
    let dueDate: Date?
    let isCompleted: Bool
    let completedAt: Date?
    let status: TodoStatus
    let prerequisiteIDs: [UUID]
    let recurrenceData: Data?

    init(from todo: TodoItem) {
        id = todo.id
        title = todo.title
        notes = todo.notes
        dueDate = todo.dueDate
        isCompleted = todo.isCompleted
        completedAt = todo.completedAt
        status = todo.status
        prerequisiteIDs = todo.prerequisiteIDs
        recurrenceData = todo.recurrenceData
    }

    func makeTodo(space: Space?) -> TodoItem {
        let t = TodoItem(title: title, space: space)
        t.id = id          // 원래 id 복원
        t.notes = notes
        t.dueDate = dueDate
        t.isCompleted = isCompleted
        t.completedAt = completedAt
        t.status = status
        t.prerequisiteIDs = prerequisiteIDs
        t.recurrenceData = recurrenceData
        return t
    }
}

// MARK: - Undo 토스트
private struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text(message)
            Spacer()
            Button("실행 취소", action: onUndo)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 8, y: 2)
        .padding(.horizontal, 24)
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

            // C3: 공유방 색상 점
            if let space = todo.space {
                Circle()
                    .fill(Color(todoHex: space.colorHex))
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.status == .locked ? .secondary : .primary)
                HStack(spacing: 6) {
                    if let due = todo.dueDate {
                        Text(due, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    // B3: 반복 배지
                    if let rule = todo.recurrence {
                        Label(rule.displayText, systemImage: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .labelStyle(.titleAndIcon)
                    }
                    // Donetick 클레이밍: 미배정 공유방 투두 강조
                    if isClaimable(todo) {
                        Text("미배정")
                            .font(.caption2)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(.blue.opacity(0.15), in: Capsule())
                            .foregroundStyle(.blue)
                    }
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
    @State private var parsedDateHint: Date?   // 자연어 파싱 결과 미리보기
    @State private var dateSetByParser = false // 파서가 자동 세팅했는지 추적

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("할 일 (예: 내일 장보기)", text: $title)
                        .onChange(of: title) { _, newValue in
                            if let result = NaturalDateParser.parse(from: newValue) {
                                parsedDateHint = result.date
                                if !hasDueDate {
                                    dueDate = result.date
                                    hasDueDate = true
                                    dateSetByParser = true
                                }
                            } else {
                                parsedDateHint = nil
                                // 파서가 자동으로 켠 날짜 토글은 파서가 힌트를 잃으면 되돌림
                                if dateSetByParser {
                                    hasDueDate = false
                                    dueDate = nil
                                    dateSetByParser = false
                                }
                            }
                        }
                    // 자연어 파싱 힌트 표시 (파서가 설정한 상태일 때만)
                    if let hint = parsedDateHint, dateSetByParser {
                        Label(
                            "날짜 인식: \(hint.formatted(.dateTime.month().day().weekday()))",
                            systemImage: "sparkles"
                        )
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }

                Toggle("날짜 지정", isOn: Binding(
                    get: { hasDueDate },
                    set: { newVal in
                        hasDueDate = newVal
                        // 사용자가 직접 토글 끄면 파서 힌트도 해제
                        if !newVal {
                            parsedDateHint = nil
                            dateSetByParser = false
                        }
                    }
                ))
                if hasDueDate {
                    DatePicker("날짜", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0; dateSetByParser = false }
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

        // 예약돼 있던 마감 알림 취소
        let completedID = todo.id
        Task { @MainActor in
            NotificationManager.shared.cancelDeadlineReminders(for: completedID)
        }

        // 반복이면 다음 투두 생성 + 마감 알림 재예약
        if let rule = todo.recurrence {
            let base: Date = rule.frequency == .afterCompletion ? Date() : (todo.dueDate ?? Date())
            if let nextDate = rule.nextOccurrence(after: base) {
                let next = TodoItem(title: todo.title, space: todo.space)
                next.dueDate = nextDate
                next.recurrence = rule
                next.templateID = todo.templateID
                context.insert(next)
                Task { @MainActor in
                    NotificationManager.shared.scheduleDeadlineReminders(for: next)
                }
            }
        }

        // 후속 투두 잠금 해제
        unlockDependents(of: todo, context: context)
    }

    /// 선행 조건 추가 시 순환 참조 검사. true면 사이클이 생기므로 거부해야 함.
    /// prereq를 todo의 선행으로 추가하면 prereq가 (간접적으로) todo에 의존하는지 검사.
    public static func wouldCreateCycle(
        addingPrerequisite prereq: TodoItem,
        to todo: TodoItem,
        allTodos: [TodoItem]
    ) -> Bool {
        let byID = Dictionary(uniqueKeysWithValues: allTodos.map { ($0.id, $0) })
        var visited = Set<UUID>()

        // prereq에서 출발해 선행 사슬을 따라가다 todo.id를 만나면 사이클
        func reaches(_ currentID: UUID) -> Bool {
            if currentID == todo.id { return true }
            if !visited.insert(currentID).inserted { return false }
            let prereqs = byID[currentID]?.prerequisiteIDs ?? []
            return prereqs.contains(where: reaches)
        }
        return reaches(prereq.id)
    }

    /// 선행 조건 추가 (사이클이면 false 반환, 추가 안 함)
    @discardableResult
    public static func addPrerequisite(
        _ prereq: TodoItem,
        to todo: TodoItem,
        allTodos: [TodoItem]
    ) -> Bool {
        guard prereq.id != todo.id else { return false }
        guard !todo.prerequisiteIDs.contains(prereq.id) else { return true }
        guard !wouldCreateCycle(addingPrerequisite: prereq, to: todo, allTodos: allTodos) else {
            return false
        }
        todo.prerequisiteIDs.append(prereq.id)
        if !prereq.isCompleted {
            todo.status = .locked
        }
        return true
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
            // ★ 시그니처 알림: "이제 할 수 있어요"
            let title = todo.title
            let spaceID = todo.space?.id
            let todoID = todo.id
            Task { @MainActor in
                NotificationManager.shared.post(
                    .chainUnlocked(title: title),
                    spaceID: spaceID,
                    todoID: todoID
                )
            }
        }
    }
}

// MARK: - Preview (시각 검증 대체물)
#Preview("투두 리스트") {
    let container = try! ModelContainer(
        for: TodoItem.self, Space.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    let a = TodoItem(title: "장보기"); a.dueDate = Date()
    let b = TodoItem(title: "요리하기"); b.status = .locked; b.prerequisiteIDs = [a.id]
    let c = TodoItem(title: "설거지"); c.isCompleted = true; c.completedAt = Date(); c.status = .completed
    [a, b, c].forEach { ctx.insert($0) }
    return NavigationStack { TodoListView() }
        .modelContainer(container)
}

// MARK: - Color hex 헬퍼 (TodoFeature 로컬 — 모듈 간 충돌 없음)
extension Color {
    init(todoHex hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
