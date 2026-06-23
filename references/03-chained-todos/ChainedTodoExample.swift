import Foundation
import SwiftData

enum TodoStatus: String, Codable {
    case locked     // 선행 미완료
    case available  // 진행 가능
    case completed
}

@Model
final class ChainedTodo {
    var id: UUID
    var title: String
    var status: TodoStatus
    var prerequisiteIDs: [UUID]  // 선행 투두 ID 목록

    init(title: String, prerequisites: [ChainedTodo] = []) {
        self.id = UUID()
        self.title = title
        self.prerequisiteIDs = prerequisites.map(\.id)
        self.status = prerequisites.isEmpty ? .available : .locked
    }
}

// MARK: - 체인 상태 업데이트
final class ChainManager {
    /// 특정 투두 완료 시 후속 투두들 상태 재계산
    static func onComplete(_ completedTodo: ChainedTodo, allTodos: [ChainedTodo]) {
        completedTodo.status = .completed

        let completedIDs = Set(allTodos.filter { $0.status == .completed }.map(\.id))

        for todo in allTodos where todo.status == .locked {
            let prereqsMet = todo.prerequisiteIDs.allSatisfy { completedIDs.contains($0) }
            if prereqsMet {
                todo.status = .available
                // TODO: 담당자에게 로컬/푸시 알림 발송
            }
        }
    }

    /// 사이클 감지 (DFS)
    static func hasCycle(
        from startID: UUID,
        to targetID: UUID,
        in todos: [ChainedTodo]
    ) -> Bool {
        let todoMap = Dictionary(uniqueKeysWithValues: todos.map { ($0.id, $0) })
        var visited = Set<UUID>()

        func dfs(_ currentID: UUID) -> Bool {
            if currentID == targetID { return true }
            if visited.contains(currentID) { return false }
            visited.insert(currentID)
            let prereqs = todoMap[currentID]?.prerequisiteIDs ?? []
            return prereqs.contains { dfs($0) }
        }

        return dfs(startID)
    }

    /// 선행 투두 추가 (사이클 체크 포함)
    static func addPrerequisite(
        _ prereq: ChainedTodo,
        to todo: ChainedTodo,
        allTodos: [ChainedTodo]
    ) throws {
        if hasCycle(from: prereq.id, to: todo.id, in: allTodos) {
            throw ChainError.cyclicDependency
        }
        todo.prerequisiteIDs.append(prereq.id)
        todo.status = .locked
    }
}

enum ChainError: Error {
    case cyclicDependency
}
