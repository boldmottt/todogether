import Testing
@testable import SpaceFeature
import SharedModels

@Suite("Space")
struct SpaceFeatureTests {
    @Test func createSpaceDefaultColor() {
        let space = Space(name: "팀 A")
        #expect(space.colorHex == "#5E5CE6")
        #expect(space.todos.isEmpty)
    }
}
