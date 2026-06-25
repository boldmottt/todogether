import Testing
@testable import SharedModels

@Suite("RecurrenceRule")
struct RecurrenceRuleTests {
    @Test func dailyNextOccurrence() {
        let rule = RecurrenceRule(frequency: .daily, interval: 1)
        let base = Date(timeIntervalSince1970: 0)
        let next = rule.nextOccurrence(after: base)
        #expect(next != nil)
        #expect(next! > base)
    }

    @Test func afterCompletionInterval() {
        let rule = RecurrenceRule(frequency: .afterCompletion, interval: 3)
        let base = Date()
        let next = rule.nextOccurrence(after: base)
        let expected = Calendar.current.date(byAdding: .day, value: 3, to: base)!
        #expect(abs(next!.timeIntervalSince(expected)) < 1)
    }

    @Test func endDateStopsRecurrence() {
        var rule = RecurrenceRule(frequency: .daily, interval: 1)
        rule.endDate = Date(timeIntervalSince1970: 86400)  // 1일 후
        let base = Date(timeIntervalSince1970: 86400 * 2)  // 2일 후 기준
        #expect(rule.nextOccurrence(after: base) == nil)
    }
}
