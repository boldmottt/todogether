import SwiftUI
import SwiftData
import SharedModels

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
    }
}

struct TemplateRowView: View {
    let template: TodoTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(template.name)
            Text("\(template.items.count)개 항목")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
                Section("항목") {
                    ForEach(items) { item in
                        Text(item.title)
                    }
                    .onDelete { items.remove(atOffsets: $0) }
                    .onMove { items.move(fromOffsets: $0, toOffset: $1) }

                    HStack {
                        TextField("항목 추가", text: $newItemTitle)
                        Button("추가") {
                            guard !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            items.append(TemplateItem(title: newItemTitle.trimmingCharacters(in: .whitespaces)))
                            newItemTitle = ""
                        }
                    }
                }
            }
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

    private func save() {
        let template = TodoTemplate(name: name.trimmingCharacters(in: .whitespaces), items: items)
        context.insert(template)
        dismiss()
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

        for (index, item) in template.items.enumerated() {
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
            _ = index
        }

        return created
    }
}
