import SwiftUI

// MARK: - 현재 사용자 식별 (Environment 주입)
//
// 실제로는 CloudKit userRecordID + iCloud 이름을 앱 진입 시 채워 넣는다.
// 미로그인/개인 사용 시 local 기본값을 쓴다.
public struct CurrentUser: Equatable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    public static let local = CurrentUser(id: "local", name: "나")
}

private struct CurrentUserKey: EnvironmentKey {
    static let defaultValue: CurrentUser = .local
}

public extension EnvironmentValues {
    var currentUser: CurrentUser {
        get { self[CurrentUserKey.self] }
        set { self[CurrentUserKey.self] = newValue }
    }
}

public extension View {
    func currentUser(_ user: CurrentUser) -> some View {
        environment(\.currentUser, user)
    }
}
