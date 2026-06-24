import SwiftUI
import AuthenticationServices
import Security

// MARK: - Keychain 헬퍼 (Apple User ID는 보안 자격증명이므로 Keychain 저장)
private enum KeychainHelper {
    static func save(_ value: String, key: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    static func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Apple 로그인 컨트롤러
@MainActor
final class AppleSignInController: ObservableObject {
    @Published var currentUser: CurrentUser = .local

    private static let userIDKey = "appleUserID"
    private static let userNameKey = "appleUserName"
    // Formatter 재사용 (handleCredential 호출마다 allocate 방지)
    private static let nameFormatter = PersonNameComponentsFormatter()

    init() {
        // 키체인에서 저장된 자격증명 복원
        if let id = KeychainHelper.load(key: Self.userIDKey),
           let name = KeychainHelper.load(key: Self.userNameKey) {
            currentUser = CurrentUser(id: id, name: name)
        }
    }

    /// 로컬(비로그인) 사용자인지 여부 — sentinel string 의존 대신 명시적 프로퍼티
    var isSignedIn: Bool { currentUser.id != CurrentUser.local.id }

    func handleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        let id = credential.user
        let name: String
        // Apple은 최초 로그인 시에만 fullName을 제공한다.
        // 재로그인 시에는 키체인에 저장된 이름을 사용.
        if let comps = credential.fullName,
           let formatted = Self.nameFormatter.string(for: comps),
           !formatted.isEmpty {
            name = formatted
        } else {
            name = KeychainHelper.load(key: Self.userNameKey) ?? "Apple 사용자"
        }
        KeychainHelper.save(id, key: Self.userIDKey)
        KeychainHelper.save(name, key: Self.userNameKey)
        currentUser = CurrentUser(id: id, name: name)
    }

    func signOut() {
        KeychainHelper.delete(key: Self.userIDKey)
        KeychainHelper.delete(key: Self.userNameKey)
        currentUser = .local
    }
}

// MARK: - Apple 로그인 화면
struct AppleSignInView: View {
    @ObservedObject var controller: AppleSignInController
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "checklist.checked")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                Text("todogether")
                    .font(SketchTheme.title)
                Text("함께 만드는 할 일 목록")
                    .font(SketchTheme.body)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                            controller.handleCredential(credential)
                        }
                    case .failure:
                        break
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)

                Button("로그인 없이 시작") {
                    onSkip()
                }
                .font(SketchTheme.body)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)

            Spacer()

            Text("Apple 계정으로 로그인하면 공유방 기능과\n실시간 동기화를 이용할 수 있어요.")
                .font(SketchTheme.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)
        }
    }
}
