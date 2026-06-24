import SwiftUI
import AuthenticationServices
import NotificationFeature

// MARK: - 설정 탭
public struct SettingsView: View {
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("didDismissSignIn") private var didDismissSignIn = false
    @State private var notificationSettings = NotificationSettings.load()
    @ObservedObject var signIn: AppleSignInController

    public init(signIn: AppleSignInController) {
        self.signIn = signIn
    }

    public var body: some View {
        List {
            // 계정
            Section("계정") {
                if signIn.isSignedIn {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(SketchTheme.headline)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(signIn.currentUser.name)
                                .font(SketchTheme.headline)
                            Text("Apple 계정으로 로그인됨")
                                .font(SketchTheme.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    Button("로그아웃", role: .destructive) {
                        signIn.signOut()
                        didDismissSignIn = false   // 다음 실행 때 로그인 화면 다시 표시
                    }
                } else {
                    // 미로그인 상태 — 설정에서도 로그인 가능
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        if case .success(let auth) = result,
                           let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                            signIn.handleCredential(credential)
                            didDismissSignIn = false
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                    .cornerRadius(10)
                    .padding(.vertical, 4)
                }
            }

            // 보안
            Section("보안") {
                Toggle("Face ID / Touch ID 잠금", isOn: $appLockEnabled)
                Text("앱 실행 및 백그라운드 복귀 시 생체 인증이 필요합니다.")
                    .font(SketchTheme.caption)
                    .foregroundStyle(.secondary)
            }

            // 알림
            Section {
                NavigationLink("알림 설정") {
                    NotificationSettingsView(settings: $notificationSettings)
                        .navigationTitle("알림 설정")
                        .onChange(of: notificationSettings) { _, new in new.save() }
                }
            } header: {
                Text("알림")
            }

            // 앱 정보
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
