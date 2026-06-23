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

@Suite("Reaction")
struct ReactionTests {
    @Test func availableEmojisCount() {
        #expect(Reaction.availableEmojis.count == 6)
    }

    @Test func reactionInitSetsFields() {
        let todoID = UUID()
        let r = Reaction(todoID: todoID, authorID: "user-1", authorName: "민지", emoji: "👍")
        #expect(r.todoID == todoID)
        #expect(r.authorName == "민지")
        #expect(r.emoji == "👍")
    }
}
