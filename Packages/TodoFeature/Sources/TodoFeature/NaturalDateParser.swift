import Foundation

// MARK: - 자연어 날짜 파서 (Reminders / Fantastical 레퍼런스)
// 지원: "오늘", "내일", "모레", "이번주 수요일", "다음주 월요일", "3일 후", "다음달 15일"
// iOS 17+ (#/.../#  regex literal requires iOS 16+)
public enum NaturalDateParser {

    public struct Result {
        public let date: Date
        public let rangeInTitle: Range<String.Index>
    }

    /// 제목에서 날짜 힌트를 찾아 첫 번째 매칭 반환.
    public static func parse(from text: String) -> Result? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for rule in rules {
            if let result = rule(text, today, cal) { return result }
        }
        return nil
    }

    // MARK: - 규칙 (구체적인 것 먼저)
    private static let rules: [(String, Date, Calendar) -> Result?] = [
        dayOfWeekRule(keyword: "다음주", weekOffset: 1),
        dayOfWeekRule(keyword: "이번주", weekOffset: 0),
        nDaysLater,
        nthOfNextMonth,
        simpleKeyword("오늘", offset: 0),
        simpleKeyword("내일", offset: 1),
        simpleKeyword("모레", offset: 2),
        simpleKeyword("글피", offset: 3),
    ]

    // MARK: - "오늘 / 내일 / 모레 / 글피"
    private static func simpleKeyword(_ kw: String, offset: Int) -> (String, Date, Calendar) -> Result? {
        { text, today, cal in
            guard let range = text.range(of: kw) else { return nil }
            let date = cal.date(byAdding: .day, value: offset, to: today) ?? today
            return Result(date: date, rangeInTitle: range)
        }
    }

    // MARK: - "이번주/다음주 + 요일"
    private static func dayOfWeekRule(keyword: String, weekOffset: Int) -> (String, Date, Calendar) -> Result? {
        { text, today, cal in
            guard let kwRange = text.range(of: keyword) else { return nil }
            // Use String ranges throughout to avoid index arithmetic crashes on
            // multi-scalar grapheme clusters or emoji in user-supplied input.
            let afterStart = kwRange.upperBound
            let afterText = String(text[afterStart...]).drop(while: { $0 == " " })
            let spacesSkipped = text[afterStart...].prefix(while: { $0 == " " }).count

            // Long forms ("월요일") before short ("월") — order preserved in weekdayNames
            for (name, wd) in weekdayNames {
                guard afterText.hasPrefix(name) else { continue }
                // Build the full matched range safely using String.Index
                let nameStart = text.index(afterStart, offsetBy: spacesSkipped,
                                           limitedBy: text.endIndex) ?? text.endIndex
                let nameEnd = text.index(nameStart, offsetBy: name.count,
                                         limitedBy: text.endIndex) ?? text.endIndex
                let fullRange = kwRange.lowerBound..<nameEnd
                if let date = nextWeekday(wd, weekOffset: weekOffset, from: today, cal: cal) {
                    return Result(date: date, rangeInTitle: fullRange)
                }
            }
            return nil
        }
    }

    // MARK: - "N일 후 / N일 뒤"
    private static func nDaysLater(text: String, today: Date, cal: Calendar) -> Result? {
        let pattern = #/(\d+)일\s*(후|뒤)/#
        guard let match = text.firstMatch(of: pattern),
              let n = Int(match.1) else { return nil }
        let date = cal.date(byAdding: .day, value: n, to: today) ?? today
        return Result(date: date, rangeInTitle: match.range)
    }

    // MARK: - "다음달 N일"
    private static func nthOfNextMonth(text: String, today: Date, cal: Calendar) -> Result? {
        let pattern = #/다음달\s*(\d+)일/#
        guard let match = text.firstMatch(of: pattern),
              let day = Int(match.1) else { return nil }
        var comps = cal.dateComponents([.year, .month], from: today)
        comps.month = (comps.month ?? 1) + 1
        // Validate that the day exists in the target month before setting it
        if let anchor = cal.date(from: comps),
           let range = cal.range(of: .day, in: .month, for: anchor),
           range.contains(day) {
            comps.day = day
            guard let date = cal.date(from: comps) else { return nil }
            return Result(date: date, rangeInTitle: match.range)
        }
        return nil
    }

    // MARK: - Weekday names (long forms first to avoid short-prefix false matches)
    // 1=Sun ... 7=Sat  (Calendar.component(.weekday))
    private static let weekdayNames: [(String, Int)] = [
        ("일요일", 1), ("월요일", 2), ("화요일", 3), ("수요일", 4),
        ("목요일", 5), ("금요일", 6), ("토요일", 7),
        ("일", 1), ("월", 2), ("화", 3), ("수", 4), ("목", 5), ("금", 6), ("토", 7),
    ]

    private static func nextWeekday(_ target: Int, weekOffset: Int, from base: Date, cal: Calendar) -> Date? {
        let todayWD = cal.component(.weekday, from: base) // 1=Sun
        var daysToTarget = target - todayWD               // negative = earlier this week
        if weekOffset == 0 {
            // 이번주: include today (daysToTarget == 0); skip only days already past
            if daysToTarget < 0 { daysToTarget += 7 }
        } else {
            // 다음주: jump exactly `weekOffset` weeks forward, then add day offset.
            // Do NOT double-add +7 here — that was a bug for e.g. Saturday + "다음주 월요일"
            daysToTarget += 7 * weekOffset
        }
        return cal.date(byAdding: .day, value: daysToTarget, to: base)
    }
}
