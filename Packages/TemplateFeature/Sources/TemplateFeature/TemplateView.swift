import SwiftUI
import SwiftData
import SharedModels

// TemplateItem은 SharedModels에 Equatable 미선언이라, onChange(of:) 등에서 쓰기 위해 여기서 채택한다.
extension TemplateItem: Equatable {
    public static func == (lhs: TemplateItem, rhs: TemplateItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.relativeDeadlineDays == rhs.relativeDeadlineDays &&
        lhs.assigneeRole == rhs.assigneeRole &&
        lhs.prerequisiteIndex == rhs.prerequisiteIndex
    }
}

// MARK: - 템플릿 목록
public struct TemplateListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TodoTemplate.name) private var templates: [TodoTemplate]
    @State private var showCreateSheet = false

    public init() {}

    public var body: some View {
        List(templates) { template in
            NavigationLink(value: template) {
                TemplateRowView(template: template)
            }
        }
        .navigationTitle("템플릿")
        .toolbar {
            Button("추가", systemImage: "plus") { showCreateSheet = true }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateTemplateView()
        }
        .navigationDestination(for: TodoTemplate.self) { template in
            TemplateDetailView(template: template)
        }
        .overlay {
            if templates.isEmpty {
                ContentUnavailableView("템플릿이 없어요", systemImage: "square.on.square", description: Text("오른쪽 위 + 버튼으로 추가하세요"))
            }
        }
        .onAppear {
            seedDefaultTemplatesIfNeeded(context: context)
        }
    }
}

struct TemplateRowView: View {
    let template: TodoTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(template.name)
            Text("\(template.items.count)개 항목")
                .font(SketchTheme.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 템플릿 상세 (편집 + 인스턴스화)
public struct TemplateDetailView: View {
    @Bindable var template: TodoTemplate
    @Environment(\.modelContext) private var context

    @State private var name: String
    @State private var items: [TemplateItem]
    @State private var newItemTitle = ""
    @State private var showInstantiate = false

    public init(template: TodoTemplate) {
        self.template = template
        _name = State(initialValue: template.name)
        _items = State(initialValue: template.items)
    }

    public var body: some View {
        Form {
            Section("템플릿 이름") {
                TextField("이름", text: $name)
                    .onChange(of: name) { _, newValue in
                        template.name = newValue
                    }
            }

            Section {
                ForEach($items) { $item in
                    NavigationLink {
                        TemplateItemEditorView(item: $item, earlierItems: earlierItems(before: item))
                    } label: {
                        TemplateItemRow(item: item, items: items)
                    }
                }
                .onDelete { offsets in
                    items.remove(atOffsets: offsets)
                    normalizePrerequisites()
                }
                .onMove { source, destination in
                    items.move(fromOffsets: source, toOffset: destination)
                    normalizePrerequisites()
                }

                HStack {
                    TextField("항목 추가", text: $newItemTitle)
                    Button("추가") {
                        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        items.append(TemplateItem(title: trimmed))
                        newItemTitle = ""
                    }
                }
            } header: {
                Text("항목")
            } footer: {
                Text("항목을 눌러 기준일·선행 항목을 설정하세요")
            }

            Section {
                Button {
                    showInstantiate = true
                } label: {
                    Label("이 템플릿으로 투두 만들기", systemImage: "wand.and.stars")
                }
                .disabled(items.isEmpty)
            }
        }
        .sketchForm()
        .navigationTitle("템플릿")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .onChange(of: items) { _, newValue in
            template.items = newValue
        }
        .sheet(isPresented: $showInstantiate) {
            InstantiationSheet(template: template)
        }
    }

    /// 현재 항목보다 앞에 위치한 항목들 (선행 후보) — (원래 인덱스, 항목)
    private func earlierItems(before item: TemplateItem) -> [(index: Int, item: TemplateItem)] {
        guard let currentIndex = items.firstIndex(where: { $0.id == item.id }) else { return [] }
        return items.enumerated()
            .filter { $0.offset < currentIndex }
            .map { (index: $0.offset, item: $0.element) }
    }

    /// 삭제/이동 후 prerequisiteIndex가 더 이상 "앞 항목"을 가리키지 않으면 초기화
    private func normalizePrerequisites() {
        for i in items.indices {
            if let prereq = items[i].prerequisiteIndex, !(prereq < i) {
                items[i].prerequisiteIndex = nil
            }
        }
    }
}

struct TemplateItemRow: View {
    let item: TemplateItem
    let items: [TemplateItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
            HStack(spacing: 8) {
                if let days = item.relativeDeadlineDays {
                    Label("기준일 +\(days)일", systemImage: "calendar")
                }
                if let prereq = item.prerequisiteIndex, items.indices.contains(prereq) {
                    Label(items[prereq].title, systemImage: "link")
                }
            }
            .font(SketchTheme.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 항목 편집 (F1)
struct TemplateItemEditorView: View {
    @Binding var item: TemplateItem
    /// 같은 템플릿 내에서 이 항목보다 앞에 있는 항목들 (원래 인덱스 포함)
    let earlierItems: [(index: Int, item: TemplateItem)]

    var body: some View {
        Form {
            Section("제목") {
                TextField("제목", text: $item.title)
            }

            Section("기준일") {
                Toggle("마감일 지정 (기준일 +N일)", isOn: hasDeadlineBinding)
                if item.relativeDeadlineDays != nil {
                    Stepper(value: deadlineDaysBinding, in: 0...365) {
                        Text("기준일 +\(item.relativeDeadlineDays ?? 0)일")
                    }
                }
            }

            Section {
                Picker("이 항목 전에 끝낼 항목", selection: prerequisiteBinding) {
                    Text("없음").tag(Int?.none)
                    ForEach(earlierItems, id: \.index) { entry in
                        Text(entry.item.title).tag(Int?.some(entry.index))
                    }
                }
            } header: {
                Text("선행 항목")
            } footer: {
                if earlierItems.isEmpty {
                    Text("앞에 있는 항목이 없어 선행 항목을 지정할 수 없어요. 항목 순서를 바꿔 보세요.")
                } else {
                    Text("선행 항목이 완료되면 이 항목이 활성화돼요")
                }
            }
        }
        .sketchForm()
        .navigationTitle("항목 설정")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hasDeadlineBinding: Binding<Bool> {
        Binding(
            get: { item.relativeDeadlineDays != nil },
            set: { item.relativeDeadlineDays = $0 ? (item.relativeDeadlineDays ?? 0) : nil }
        )
    }

    private var deadlineDaysBinding: Binding<Int> {
        Binding(
            get: { item.relativeDeadlineDays ?? 0 },
            set: { item.relativeDeadlineDays = $0 }
        )
    }

    private var prerequisiteBinding: Binding<Int?> {
        Binding(
            get: { item.prerequisiteIndex },
            set: { item.prerequisiteIndex = $0 }
        )
    }
}

// MARK: - 템플릿 생성
struct CreateTemplateView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var items: [TemplateItem] = []
    @State private var newItemTitle = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("템플릿 이름") {
                    TextField("예: 주간 청소", text: $name)
                }
                Section {
                    ForEach($items) { $item in
                        NavigationLink {
                            TemplateItemEditorView(item: $item, earlierItems: earlierItems(before: item))
                        } label: {
                            TemplateItemRow(item: item, items: items)
                        }
                    }
                    .onDelete { offsets in
                        items.remove(atOffsets: offsets)
                        normalizePrerequisites()
                    }
                    .onMove { source, destination in
                        items.move(fromOffsets: source, toOffset: destination)
                        normalizePrerequisites()
                    }

                    HStack {
                        TextField("항목 추가", text: $newItemTitle)
                        Button("추가") {
                            let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            items.append(TemplateItem(title: trimmed))
                            newItemTitle = ""
                        }
                    }
                } header: {
                    Text("항목")
                } footer: {
                    Text("항목을 눌러 기준일·선행 항목을 설정하세요")
                }
            }
            .sketchForm()
            .navigationTitle("새 템플릿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
            }
        }
    }

    private func earlierItems(before item: TemplateItem) -> [(index: Int, item: TemplateItem)] {
        guard let currentIndex = items.firstIndex(where: { $0.id == item.id }) else { return [] }
        return items.enumerated()
            .filter { $0.offset < currentIndex }
            .map { (index: $0.offset, item: $0.element) }
    }

    private func normalizePrerequisites() {
        for i in items.indices {
            if let prereq = items[i].prerequisiteIndex, !(prereq < i) {
                items[i].prerequisiteIndex = nil
            }
        }
    }

    private func save() {
        let template = TodoTemplate(name: name.trimmingCharacters(in: .whitespaces), items: items)
        context.insert(template)
        dismiss()
    }
}

// MARK: - 인스턴스화 시트 (F2)
struct InstantiationSheet: View {
    let template: TodoTemplate
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Space.name) private var spaces: [Space]

    @State private var startDate = Date()
    @State private var selectedSpaceID: UUID?   // nil = 내 투두
    @State private var showConfirmation = false
    @State private var createdCount = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("기준일") {
                    DatePicker("기준일", selection: $startDate, displayedComponents: [.date])
                }

                Section("대상") {
                    Picker("공유방", selection: $selectedSpaceID) {
                        Text("내 투두").tag(UUID?.none)
                        ForEach(spaces) { space in
                            Text(space.name).tag(UUID?.some(space.id))
                        }
                    }
                }

                Section {
                    Text("\(template.items.count)개 항목이 생성됩니다")
                        .font(SketchTheme.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .sketchForm()
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("만들기") { instantiate() }
                        .disabled(template.items.isEmpty)
                }
            }
            .alert("생성 완료", isPresented: $showConfirmation) {
                Button("확인") { dismiss() }
            } message: {
                Text("\(createdCount)개의 투두를 만들었어요")
            }
        }
    }

    private func selectedSpace() -> Space? {
        guard let id = selectedSpaceID else { return nil }
        return spaces.first { $0.id == id }
    }

    private func instantiate() {
        let created = TemplateInstantiator.instantiate(
            template,
            startDate: startDate,
            space: selectedSpace(),
            context: context
        )
        createdCount = created.count
        showConfirmation = true
    }
}

// MARK: - 템플릿 인스턴스화
public enum TemplateInstantiator {
    /// 템플릿을 기준일 기반으로 TodoItem 배열 생성
    public static func instantiate(
        _ template: TodoTemplate,
        startDate: Date = Date(),
        space: Space? = nil,
        context: ModelContext
    ) -> [TodoItem] {
        var created: [TodoItem] = []

        for item in template.items {
            let todo = TodoItem(title: item.title, space: space)
            todo.templateID = template.id

            if let days = item.relativeDeadlineDays {
                todo.dueDate = Calendar.current.date(byAdding: .day, value: days, to: startDate)
            }

            if let prereqIdx = item.prerequisiteIndex, prereqIdx < created.count {
                todo.prerequisiteIDs = [created[prereqIdx].id]
                todo.status = .locked
            }

            context.insert(todo)
            created.append(todo)
        }

        return created
    }
}

// MARK: - 기본 템플릿 시드 (F3)
/// 템플릿이 하나도 없을 때만 기본 템플릿 3종을 추가한다.
public func seedDefaultTemplatesIfNeeded(context: ModelContext) {
    let descriptor = FetchDescriptor<TodoTemplate>()
    let existingCount = (try? context.fetchCount(descriptor)) ?? 0
    guard existingCount == 0 else { return }

    for template in DefaultTemplates.all() {
        context.insert(template)
    }
}

enum DefaultTemplates {
    static func all() -> [TodoTemplate] {
        [weeklyChores(), travelPrep(), movingChecklist()]
    }

    private static func makeItem(_ title: String, deadline: Int? = nil, prerequisite: Int? = nil) -> TemplateItem {
        var item = TemplateItem(title: title)
        item.relativeDeadlineDays = deadline
        item.prerequisiteIndex = prerequisite
        return item
    }

    // 주간 집안일
    static func weeklyChores() -> TodoTemplate {
        TodoTemplate(name: "주간 집안일", items: [
            makeItem("거실 청소기 돌리기", deadline: 0),
            makeItem("화장실 청소", deadline: 1),
            makeItem("빨래 돌리기", deadline: 2),
            makeItem("빨래 개기", deadline: 2, prerequisite: 2),
            makeItem("음식물 쓰레기 비우기", deadline: 3)
        ])
    }

    // 여행 준비
    static func travelPrep() -> TodoTemplate {
        TodoTemplate(name: "여행 준비", items: [
            makeItem("숙소 예약", deadline: 0),
            makeItem("교통편 예약", deadline: 1, prerequisite: 0),
            makeItem("짐 싸기", deadline: 5),
            makeItem("여권·신분증 확인", deadline: 5),
            makeItem("출발 전 집 점검", deadline: 6, prerequisite: 2)
        ])
    }

    // 이사 체크리스트
    static func movingChecklist() -> TodoTemplate {
        TodoTemplate(name: "이사 체크리스트", items: [
            makeItem("이사 업체 예약", deadline: 0),
            makeItem("포장 박스 준비", deadline: 7, prerequisite: 0),
            makeItem("짐 포장", deadline: 13, prerequisite: 1),
            makeItem("전입신고", deadline: 14),
            makeItem("공과금 정산", deadline: 14)
        ])
    }
}

// MARK: - Preview (시각 검증 대체물)
#Preview("템플릿 목록") {
    let container = try! ModelContainer(
        for: TodoTemplate.self, Space.self, TodoItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    for template in DefaultTemplates.all() {
        container.mainContext.insert(template)
    }
    return NavigationStack { TemplateListView() }
        .modelContainer(container)
}

#Preview("템플릿 상세") {
    let container = try! ModelContainer(
        for: TodoTemplate.self, Space.self, TodoItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let template = DefaultTemplates.travelPrep()
    container.mainContext.insert(template)
    return NavigationStack { TemplateDetailView(template: template) }
        .modelContainer(container)
}

#Preview("새 템플릿") {
    let container = try! ModelContainer(
        for: TodoTemplate.self, Space.self, TodoItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return CreateTemplateView()
        .modelContainer(container)
}

#Preview("인스턴스화 시트") {
    let container = try! ModelContainer(
        for: TodoTemplate.self, Space.self, TodoItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let template = DefaultTemplates.movingChecklist()
    container.mainContext.insert(template)
    container.mainContext.insert(Space(name: "우리집"))
    container.mainContext.insert(Space(name: "회사"))
    return InstantiationSheet(template: template)
        .modelContainer(container)
}
