import SwiftUI

// MARK: - 알림 설정 화면 (E3)
public struct NotificationSettingsView: View {
    @Binding var settings: NotificationSettings

    public init(settings: Binding<NotificationSettings>) {
        _settings = settings
    }

    public var body: some View {
        Form {
            Section("알림 종류") {
                ForEach(NotificationCategory.allCases, id: \.self) { category in
                    Toggle(label(for: category), isOn: binding(for: category))
                }
            }

            Section {
                Toggle("방해 금지 시간", isOn: quietHoursEnabled)
                if let _ = settings.quietHours {
                    HStack {
                        Text("시작")
                        Spacer()
                        Picker("시작", selection: quietStart) {
                            ForEach(0..<24, id: \.self) { Text("\($0)시").tag($0) }
                        }
                        .labelsHidden()
                    }
                    HStack {
                        Text("종료")
                        Spacer()
                        Picker("종료", selection: quietEnd) {
                            ForEach(0..<24, id: \.self) { Text("\($0)시").tag($0) }
                        }
                        .labelsHidden()
                    }
                    Toggle("방해 금지 중에도 ‘이제 할 수 있어요’ 알림 받기", isOn: $settings.chainBreaksQuietHours)
                }
            } header: {
                Text("방해 금지")
            } footer: {
                Text("자정을 넘는 구간(예: 22시~8시)도 설정할 수 있어요")
            }
        }
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func label(for c: NotificationCategory) -> String {
        switch c {
        case .deadline: "마감 알림"
        case .chain: "연계 해제 (이제 할 수 있어요)"
        case .completion: "공유방 완료 알림"
        case .assignment: "담당 지정 알림"
        case .nudge: "콕 찌르기"
        case .reaction: "반응 알림"
        }
    }

    private func binding(for c: NotificationCategory) -> Binding<Bool> {
        Binding(
            get: { settings.enabledCategories.contains(c) },
            set: { on in
                if on { settings.enabledCategories.insert(c) }
                else { settings.enabledCategories.remove(c) }
            }
        )
    }

    private var quietHoursEnabled: Binding<Bool> {
        Binding(
            get: { settings.quietHours != nil },
            set: { on in
                settings.quietHours = on ? NotificationSettings.QuietHours(start: 22, end: 8) : nil
            }
        )
    }

    private var quietStart: Binding<Int> {
        Binding(
            get: { settings.quietHours?.start ?? 22 },
            set: { settings.quietHours?.start = $0 }
        )
    }

    private var quietEnd: Binding<Int> {
        Binding(
            get: { settings.quietHours?.end ?? 8 },
            set: { settings.quietHours?.end = $0 }
        )
    }
}

#Preview("알림 설정") {
    struct Wrap: View {
        @State var settings = NotificationSettings()
        var body: some View { NavigationStack { NotificationSettingsView(settings: $settings) } }
    }
    return Wrap()
}
