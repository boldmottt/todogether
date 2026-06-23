import Testing
import Foundation
@testable import NotificationFeature

@Suite("NotificationContent")
struct NotificationContentTests {
    @Test func chainUnlockedIsImmediate() {
        #expect(NotificationKind.chainUnlocked(title: "요리").isImmediate)
        #expect(!NotificationKind.dueToday(title: "장보기").isImmediate)
    }

    @Test func completionHasReactionCategory() {
        let kind = NotificationKind.spaceCompleted(title: "설거지", byName: "민지")
        #expect(kind.categoryIdentifier == "COMPLETION_WITH_REACTION")
    }

    @Test func reactionBodyIncludesEmoji() {
        let kind = NotificationKind.reaction(title: "설거지", byName: "민지", emoji: "👍")
        #expect(kind.content.body.contains("👍"))
        #expect(kind.content.body.contains("민지"))
    }
}

@Suite("NotificationSettings")
struct NotificationSettingsTests {
    @Test func mutedCategoryBlocksDelivery() {
        var s = NotificationSettings()
        s.enabledCategories.remove(.completion)
        let kind = NotificationKind.spaceCompleted(title: "x", byName: "y")
        #expect(!s.shouldDeliver(kind, spaceID: nil, at: 12))
    }

    @Test func mutedSpaceBlocksDelivery() {
        let spaceID = UUID()
        let s = NotificationSettings(mutedSpaceIDs: [spaceID])
        let kind = NotificationKind.spaceCompleted(title: "x", byName: "y")
        #expect(!s.shouldDeliver(kind, spaceID: spaceID, at: 12))
        #expect(s.shouldDeliver(kind, spaceID: UUID(), at: 12)) // 다른 방은 통과
    }

    @Test func quietHoursBlockNormalButAllowChain() {
        let q = NotificationSettings.QuietHours(start: 22, end: 23)
        let s = NotificationSettings(quietHours: q, chainBreaksQuietHours: true)
        let normal = NotificationKind.spaceCompleted(title: "x", byName: "y")
        let chain = NotificationKind.chainUnlocked(title: "요리")
        #expect(!s.shouldDeliver(normal, spaceID: nil, at: 22))
        #expect(s.shouldDeliver(chain, spaceID: nil, at: 22)) // 연계 해제는 우회
    }

    @Test func quietHoursCanBlockChainToo() {
        let q = NotificationSettings.QuietHours(start: 22, end: 23)
        let s = NotificationSettings(quietHours: q, chainBreaksQuietHours: false)
        let chain = NotificationKind.chainUnlocked(title: "요리")
        #expect(!s.shouldDeliver(chain, spaceID: nil, at: 22))
    }

    @Test func overnightQuietHoursWrapAround() {
        // 22시 ~ 8시 (자정 넘김)
        let q = NotificationSettings.QuietHours(start: 22, end: 8)
        #expect(q.contains(23))  // 밤
        #expect(q.contains(2))   // 새벽
        #expect(q.contains(7))   // 아침 직전
        #expect(!q.contains(8))  // 끝 시각은 미포함
        #expect(!q.contains(12)) // 낮
        #expect(!q.contains(21)) // 시작 직전
    }
}

@Suite("ReactionBatcher")
struct ReactionBatcherTests {
    @Test func singleReaction() {
        let now = Date()
        let r = [ReactionBatcher.PendingReaction(authorName: "민지", emoji: "👍", at: now)]
        let text = ReactionBatcher.summarize(todoTitle: "설거지", reactions: r, now: now)
        #expect(text == "민지님이 ‘설거지’에 👍 했어요")
    }

    @Test func multiplePeopleCoalesced() {
        let now = Date()
        let r = [
            ReactionBatcher.PendingReaction(authorName: "민지", emoji: "👍", at: now),
            ReactionBatcher.PendingReaction(authorName: "지호", emoji: "❤️", at: now),
            ReactionBatcher.PendingReaction(authorName: "수아", emoji: "🎉", at: now),
        ]
        let text = ReactionBatcher.summarize(todoTitle: "설거지", reactions: r, now: now)
        #expect(text == "민지님 외 2명이 ‘설거지’에 반응했어요")
    }

    @Test func oldReactionsExcluded() {
        let now = Date()
        let old = now.addingTimeInterval(-31 * 60) // 31분 전
        let r = [ReactionBatcher.PendingReaction(authorName: "민지", emoji: "👍", at: old)]
        let text = ReactionBatcher.summarize(todoTitle: "설거지", reactions: r, now: now)
        #expect(text == nil) // window 밖 → 알림 없음
    }
}
