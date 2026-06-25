import Foundation

// MARK: - 반응 알림 묶음 처리 (PRD: 30분 단위 도배 방지)
//
// 같은 투두에 짧은 시간 동안 여러 반응이 오면 알림을 하나로 합친다.
// "민지님이 반응했어요" → "민지님 외 2명이 반응했어요"
public enum ReactionBatcher {
    public static let window: TimeInterval = 30 * 60 // 30분

    public struct PendingReaction {
        public let authorName: String
        public let emoji: String
        public let at: Date
        public init(authorName: String, emoji: String, at: Date) {
            self.authorName = authorName
            self.emoji = emoji
            self.at = at
        }
    }

    /// window 안에 들어온 반응들을 하나의 알림 문구로 합친다.
    /// 순수 함수 — 테스트 대상.
    public static func summarize(
        todoTitle: String,
        reactions: [PendingReaction],
        now: Date
    ) -> String? {
        let recent = reactions.filter { now.timeIntervalSince($0.at) <= window }
        guard let first = recent.first else { return nil }

        if recent.count == 1 {
            return "\(first.authorName)님이 ‘\(todoTitle)’에 \(first.emoji) 했어요"
        }

        // 고유 인원 수 기준으로 표현
        let uniqueNames = Array(Set(recent.map(\.authorName)))
        let others = uniqueNames.count - 1
        if others <= 0 {
            // 같은 사람이 여러 이모지 — 인원은 1명
            let emojis = recent.map(\.emoji).joined()
            return "\(first.authorName)님이 ‘\(todoTitle)’에 \(emojis) 했어요"
        }
        return "\(first.authorName)님 외 \(others)명이 ‘\(todoTitle)’에 반응했어요"
    }
}
