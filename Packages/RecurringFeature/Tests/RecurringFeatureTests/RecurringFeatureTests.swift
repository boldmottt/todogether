import Testing
@testable import RecurringFeature
import SharedModels

@Suite("RecurrenceDisplayText")
struct RecurrenceDisplayTextTests {
    @Test func dailyText() {
        let rule = RecurrenceRule(frequency: .daily, interval: 1)
        #expect(rule.displayText == "매일")
    }

    @Test func everyTwoWeeksText() {
        let rule = RecurrenceRule(frequency: .weekly, interval: 2)
        #expect(rule.displayText == "2주마다")
    }

    @Test func afterCompletionText() {
        let rule = RecurrenceRule(frequency: .afterCompletion, interval: 3)
        #expect(rule.displayText == "완료 후 3일")
    }
}
