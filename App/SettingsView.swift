import SwiftUI
import NotificationFeature

// MARK: - 설정 탭 (BUILD_PLAN 후속: 알림설정 + 앱잠금 토글 노출)
public struct SettingsView: View {
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @State private var notificationSettings = NotificationSettings.load()

    public init() {}

    public var body: some View {
        List {
            Section("보안") {
                Toggle("Face ID / Touch ID 잠금", isOn: $appLockEnabled)
                Text("앱 실행 및 백그라운드 복귀 시 생체 인증이 필요합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink("알림 설정") {
                    NotificationSettingsView(settings: $notificationSettings)
                        .navigationTitle("알림 설정")
                        .onChange(of: notificationSettings) { _, new in new.save() }
                }
            } header: {
                Text("알림")
            }

            Section("앱 정보") {
                LabeledContent("버전", value: appVersion)
            }
        }
        .navigationTitle("설정")
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
