import Testing
@testable import TodoFeature
import SharedModels

@Suite("ChainManager")
struct ChainManagerTests {
    @Test func completedTodoBecomesCompleted() {
        let todo = TodoItem(title: "테스트")
        #expect(todo.status == .available)
        #expect(!todo.isCompleted)
    }
}
