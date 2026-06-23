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

    /// 위젯에 노출할 최대 항목 수
    public static let maxWidgetTodos = 10

    /// 앱에서 TodoItem 변경 시 호출 — 위젯용 경량 모델로 변환 후 저장.
    /// 가용(available)·미완료 항목만, 마감일(dueDate) 빠른 순으로 정렬해 상위 N개만 저장한다.
    /// (마감일 없는 항목은 뒤로 보낸다.)
    public static func sync(from todos: [TodoItem]) {
        let widgetTodos = todos
            .filter { !$0.isCompleted && $0.status == .available }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (l?, r?): return l < r
                case (_?, nil): return true      // 마감일 있는 항목이 먼저
                case (nil, _?): return false
                case (nil, nil): return false
                }
            }
            .prefix(maxWidgetTodos)
            .map { WidgetTodo(id: $0.id, title: $0.title, isCompleted: $0.isCompleted, dueDate: $0.dueDate) }
        save(Array(widgetTodos))
    }
}

// MARK: - 앱에서 호출하는 위젯 동기화 진입점
/// 앱(또는 Extension)이 SwiftData 변경 후 호출하는 공개 API.
/// 위젯 코드에서 SwiftData를 직접 다루지 않고, 이 타입을 통해서만 동기화한다.
public enum WidgetSyncing {
    /// 현재 TodoItem 목록을 위젯 저장소에 반영하고 타임라인을 갱신한다.
    public static func refresh(from todos: [TodoItem]) {
        SharedStore.sync(from: todos)
    }
}

// MARK: - 딥링크 URL 빌더
/// `todogether://todo/<id>` 형태의 딥링크를 만든다. 위젯 탭 시 해당 투두로 이동.
public enum WidgetDeepLink {
    public static let scheme = "todogether"
    public static let todoHost = "todo"

    /// 특정 투두로 이동하는 딥링크.
    public static func url(for id: UUID) -> URL? {
        URL(string: "\(scheme)://\(todoHost)/\(id.uuidString)")
    }

    /// 앱 홈(투두 목록)으로 이동하는 기본 딥링크.
    public static func home() -> URL? {
        URL(string: "\(scheme)://\(todoHost)")
    }

    /// 딥링크 URL에서 투두 ID를 파싱한다. (앱의 onOpenURL 핸들러에서 사용)
    public static func todoID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host == todoHost else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
