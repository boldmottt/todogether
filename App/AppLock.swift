import SwiftUI
import LocalAuthentication

// MARK: - 앱 잠금 (I3) — Face ID / Touch ID
@MainActor
final class AppLockController: ObservableObject {
    @Published var isLocked: Bool
    private var isAuthenticating = false

    /// 설정에서 잠금 사용 여부 (AppStorage와 연동)
    var lockEnabled: Bool {
        didSet { if !lockEnabled { isLocked = false } }
    }

    init(lockEnabled: Bool) {
        self.lockEnabled = lockEnabled
        self.isLocked = lockEnabled
    }

    /// 백그라운드 진입 시 다시 잠금
    func relock() {
        if lockEnabled { isLocked = true }
    }

    func authenticate() async {
        // 재진입 가드: 프롬프트 표시 중 중복 호출 방지 (Face ID 다이얼로그 중복)
        guard lockEnabled, isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // 생체/패스코드 사용 불가 → 잠금 해제(막히지 않도록)
            isLocked = false
            return
        }
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "할 일을 보려면 잠금을 해제하세요"
            )
            isLocked = !ok
        } catch {
            // 실패 시 잠금 유지
            isLocked = true
        }
    }
}

// MARK: - 잠금 화면 오버레이
struct LockScreenView: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThickMaterial).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill").font(.system(size: 48))
                Text("todogether 잠김").font(.headline)
                Button("잠금 해제", action: onUnlock)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
