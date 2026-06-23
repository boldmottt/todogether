import Testing
import Foundation

@Suite("CalendarFeature")
struct CalendarFeatureTests {
    @Test func startOfDayIsCorrect() {
        let date = Date()
        let start = Calendar.current.startOfDay(for: date)
        #expect(Calendar.current.component(.hour, from: start) == 0)
        #expect(Calendar.current.component(.minute, from: start) == 0)
    }
}
