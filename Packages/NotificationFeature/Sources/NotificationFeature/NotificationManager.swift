import Foundation
import UserNotifications
import SharedModels

// MARK: - 알림 발행 (부수효과 래퍼)
//
// 콘텐츠 생성/게이팅은 순수 함수에 맡기고, 여기서는 실제 발행만 담당한다.
@MainActor
public final class NotificationManager {
    public static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    public var settings = NotificationSettings()

    private init() {}

    // MARK: 권한
    public func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// 완료 알림에서 바로 반응할 수 있는 액션 카테고리 등록
    public func registerCategories() {
        let reactionActions = ["👍", "❤️", "🎉"].map { emoji in
            UNNotificationAction(
                identifier: "REACT_\(emoji)",
                title: emoji,
                options: []
            )
        }
        let completion = UNNotificationCategory(
            identifier: "COMPLETION_WITH_REACTION",
            actions: reactionActions,
            intentIdentifiers: [],
            options: []
        )
        let open = UNNotificationCategory(
            identifier: "TODO_OPEN",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([completion, open])
    }

    // MARK: 즉시 발행
    public func post(_ kind: NotificationKind, spaceID: UUID? = nil, todoID: UUID? = nil) {
        let hour = Calendar.current.component(.hour, from: Date())
        guard settings.shouldDeliver(kind, spaceID: spaceID, at: hour) else { return }

        let content = UNMutableNotificationContent()
        content.title = kind.content.title
        content.body = kind.content.body
        content.sound = .default
        content.categoryIdentifier = kind.categoryIdentifier
        if let todoID { content.userInfo = ["todoID": todoID.uuidString] }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 즉시
        )
        center.add(request)
    }

    // MARK: 콕 찌르기 (E2)
    /// 1일 1회 제한을 적용해 nudge 발송. 보냈으면 true, 제한이면 false.
    @discardableResult
    public func sendNudge(
        todoID: UUID,
        todoTitle: String,
        senderID: String,
        senderName: String,
        spaceID: UUID?,
        store: NudgeStore
    ) -> Bool {
        guard store.tryNudge(todoID: todoID, senderID: senderID) else { return false }
        // 실제로는 상대 기기에 전달돼야 하므로 CloudKit 푸시 경로로 나감.
        // 로컬에서는 발송 사실만 표면화(데모/단일기기).
        post(.nudge(title: todoTitle, byName: senderName), spaceID: spaceID, todoID: todoID)
        return true
    }

    // MARK: 마감 알림 예약 (당일/전날 오전 9시)
    public func scheduleDeadlineReminders(for todo: TodoItem) {
        guard let due = todo.dueDate else { return }
        let cal = Calendar.current

        // 당일 오전 9시
        if let dueToday = cal.date(bySettingHour: 9, minute: 0, second: 0, of: due) {
            scheduleCalendar(
                kind: .dueToday(title: todo.title),
                fireDate: dueToday,
                id: "due-today-\(todo.id)",
                spaceID: todo.space?.id,
                todoID: todo.id
            )
        }
        // 전날 오전 9시
        if let prevDay = cal.date(byAdding: .day, value: -1, to: due),
           let dueTomorrow = cal.date(bySettingHour: 9, minute: 0, second: 0, of: prevDay) {
            scheduleCalendar(
                kind: .dueTomorrow(title: todo.title),
                fireDate: dueTomorrow,
                id: "due-tomorrow-\(todo.id)",
                spaceID: todo.space?.id,
                todoID: todo.id
            )
        }
    }

    /// 투두 완료/삭제 시 예약된 마감 알림 취소
    public func cancelDeadlineReminders(for todoID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "due-today-\(todoID)", "due-tomorrow-\(todoID)"
        ])
    }

    private func scheduleCalendar(
        kind: NotificationKind,
        fireDate: Date,
        id: String,
        spaceID: UUID?,
        todoID: UUID
    ) {
        guard fireDate > Date() else { return } // 이미 지난 시각은 예약 안 함
        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate
        )
        let content = UNMutableNotificationContent()
        content.title = kind.content.title
        content.body = kind.content.body
        content.sound = .default
        content.categoryIdentifier = kind.categoryIdentifier
        content.userInfo = ["todoID": todoID.uuidString]

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
