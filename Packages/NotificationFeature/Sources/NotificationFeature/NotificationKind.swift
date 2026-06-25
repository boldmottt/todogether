import Foundation

// MARK: - 알림 종류 (PRD 3.8)
public enum NotificationKind: Equatable {
    case dueToday(title: String)
    case dueTomorrow(title: String)
    case chainUnlocked(title: String)                  // ★ 시그니처
    case spaceCompleted(title: String, byName: String)
    case assigned(title: String, byName: String)
    case nudge(title: String, byName: String)          // ★ 콕 찌르기
    case reaction(title: String, byName: String, emoji: String) // ★
    case unassignedDue(title: String)

    /// 설정 게이팅에 쓰는 카테고리 (종류별 on/off 단위)
    public var category: NotificationCategory {
        switch self {
        case .dueToday, .dueTomorrow, .unassignedDue: return .deadline
        case .chainUnlocked: return .chain
        case .spaceCompleted: return .completion
        case .assigned: return .assignment
        case .nudge: return .nudge
        case .reaction: return .reaction
        }
    }

    /// 즉시 발송해야 하는 알림 (묶음/방해금지 우회)
    public var isImmediate: Bool {
        if case .chainUnlocked = self { return true }
        return false
    }

    public var content: (title: String, body: String) {
        switch self {
        case .dueToday(let t):
            return ("오늘 마감", "‘\(t)’ 오늘까지예요")
        case .dueTomorrow(let t):
            return ("내일 마감", "‘\(t)’ 내일까지예요")
        case .chainUnlocked(let t):
            return ("이제 할 수 있어요", "‘\(t)’ 차례가 왔어요 — 앞 단계가 끝났어요")
        case .spaceCompleted(let t, let by):
            return ("완료", "\(by)님이 ‘\(t)’ 끝냈어요")
        case .assigned(let t, let by):
            return ("할 일이 생겼어요", "\(by)님이 ‘\(t)’을(를) 맡겼어요")
        case .nudge(let t, let by):
            return ("콕!", "\(by)님이 ‘\(t)’ 슬쩍 알려줬어요")
        case .reaction(let t, let by, let emoji):
            return ("반응", "\(by)님이 ‘\(t)’에 \(emoji) 했어요")
        case .unassignedDue(let t):
            return ("아직 아무도 안 했어요", "‘\(t)’ 오늘까지인데 담당자가 없어요")
        }
    }

    /// iOS 알림 카테고리 식별자 (액션 버튼 부착용)
    public var categoryIdentifier: String {
        switch self {
        case .spaceCompleted: return "COMPLETION_WITH_REACTION" // 👍 ❤️ 🎉 액션
        case .nudge, .assigned, .dueToday, .dueTomorrow, .unassignedDue: return "TODO_OPEN"
        case .chainUnlocked: return "TODO_OPEN"
        case .reaction: return "DEFAULT"
        }
    }
}

public enum NotificationCategory: String, CaseIterable, Codable {
    case deadline, chain, completion, assignment, nudge, reaction
}
