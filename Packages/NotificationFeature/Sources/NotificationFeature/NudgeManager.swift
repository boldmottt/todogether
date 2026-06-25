import Foundation

// MARK: - 콕 찌르기 (Nudge) — PRD 3.8 시그니처 알림
//
// 다른 멤버의 미완료 투두를 가볍게 재촉. 같은 투두에 같은 사람이
// 하루 1회만 보낼 수 있도록 제한(도배 방지).
public enum NudgeManager {

    /// 1일 1회 제한 판정 (순수 함수 — 테스트 대상)
    /// - lastNudge: (해당 투두에 대해) 이 사용자가 마지막으로 보낸 시각. 없으면 nil.
    public static func canNudge(lastNudge: Date?, now: Date = Date()) -> Bool {
        guard let lastNudge else { return true }
        return !Calendar.current.isDate(lastNudge, inSameDayAs: now)
    }

    /// 키: "투두id:보낸사람id" → 마지막 발송 시각 (UserDefaults 등에 저장)
    public static func storageKey(todoID: UUID, senderID: String) -> String {
        "nudge.\(todoID.uuidString).\(senderID)"
    }
}

// MARK: - Nudge 기록 저장소 (App Group UserDefaults)
public final class NudgeStore {
    private let defaults: UserDefaults

    public init(suiteName: String? = nil) {
        self.defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    public func lastNudge(todoID: UUID, senderID: String) -> Date? {
        defaults.object(forKey: NudgeManager.storageKey(todoID: todoID, senderID: senderID)) as? Date
    }

    /// 보낼 수 있으면 기록하고 true, 제한이면 false
    @discardableResult
    public func tryNudge(todoID: UUID, senderID: String, now: Date = Date()) -> Bool {
        let last = lastNudge(todoID: todoID, senderID: senderID)
        guard NudgeManager.canNudge(lastNudge: last, now: now) else { return false }
        defaults.set(now, forKey: NudgeManager.storageKey(todoID: todoID, senderID: senderID))
        return true
    }
}
