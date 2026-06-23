import Foundation

// MARK: - 알림 설정 (PRD 3.8 설정 화면)
public struct NotificationSettings: Codable, Equatable {
    /// 방해 금지 시간 구간. 자정을 넘는 구간(예: 22시~8시)도 표현 가능.
    public struct QuietHours: Codable, Equatable {
        public var start: Int // 0~23
        public var end: Int   // 0~23
        public init(start: Int, end: Int) {
            self.start = start
            self.end = end
        }
        /// 주어진 시각이 방해 금지 구간 안인지 (자정 넘김 처리)
        public func contains(_ hour: Int) -> Bool {
            if start == end { return false }          // 빈 구간
            if start < end { return (start..<end).contains(hour) }
            // 자정 넘김: start..23 또는 0..<end
            return hour >= start || hour < end
        }
    }

    /// 종류별 on/off
    public var enabledCategories: Set<NotificationCategory>
    /// 공유방별 off 목록 (여기 든 Space는 알림 안 옴)
    public var mutedSpaceIDs: Set<UUID>
    /// 방해 금지 시간. nil이면 미설정
    public var quietHours: QuietHours?
    /// 방해 금지 중에도 연계 해제 알림은 보낼지
    public var chainBreaksQuietHours: Bool

    public init(
        enabledCategories: Set<NotificationCategory> = Set(NotificationCategory.allCases),
        mutedSpaceIDs: Set<UUID> = [],
        quietHours: QuietHours? = nil,
        chainBreaksQuietHours: Bool = true
    ) {
        self.enabledCategories = enabledCategories
        self.mutedSpaceIDs = mutedSpaceIDs
        self.quietHours = quietHours
        self.chainBreaksQuietHours = chainBreaksQuietHours
    }

    /// 이 알림을 지금 보낼 수 있는지 (순수 함수 — 테스트 대상)
    public func shouldDeliver(
        _ kind: NotificationKind,
        spaceID: UUID?,
        at hour: Int
    ) -> Bool {
        // 종류별 off
        guard enabledCategories.contains(kind.category) else { return false }
        // 공유방별 off
        if let spaceID, mutedSpaceIDs.contains(spaceID) { return false }
        // 방해 금지 시간
        if let quietHours, quietHours.contains(hour) {  // 자정 넘김 구간도 처리
            // 연계 해제는 예외적으로 허용 가능
            if kind.isImmediate && chainBreaksQuietHours { return true }
            return false
        }
        return true
    }

    public static let `default` = NotificationSettings()

    // MARK: - UserDefaults persistence
    private static let udKey = "notificationSettings"

    public static func load() -> NotificationSettings {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data)
        else { return .default }
        return decoded
    }

    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.udKey)
        }
    }
}
