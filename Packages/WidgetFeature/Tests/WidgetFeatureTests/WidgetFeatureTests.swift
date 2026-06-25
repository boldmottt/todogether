import Testing
@testable import WidgetFeature
import SharedModels

@Suite("SharedStore")
struct SharedStoreTests {
    @Test func emptyWhenNoFile() {
        // App Group 없는 테스트 환경에서는 빈 배열 반환
        let todos = SharedStore.load()
        #expect(todos.isEmpty)
    }
}
