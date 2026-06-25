import SwiftUI
import SwiftData
import SharedModels
import SpaceFeature
import TodoFeature
import CalendarFeature
import TemplateFeature
import NotificationFeature
import WidgetFeature

@main
struct TodogetherApp: App {
    @State private var deepLinkedTodoID: UUID?
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("didOnboard") private var didOnboard = false
    @AppStorage("didDismissSignIn") private var didDismissSignIn = false
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @StateObject private var lock: AppLockController
    @StateObject private var signIn: AppleSignInController

    let container: ModelContainer = try! ModelContainer.makeShared()

    init() {
        let enabled = UserDefaults.standard.bool(forKey: "appLockEnabled")
        _lock = StateObject(wrappedValue: AppLockController(lockEnabled: enabled))
        _signIn = StateObject(wrappedValue: AppleSignInController())
    }

    private var currentUser: CurrentUser { signIn.currentUser }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(deepLinkedTodoID: $deepLinkedTodoID, signIn: signIn)
                    .currentUser(currentUser)
                    .task {
                        NotificationManager.shared.registerCategories()
                        _ = await NotificationManager.shared.requestAuthorization()
                        // TODO: CloudKit userRecordID + iCloud 이름으로 currentUser 채우기
                    }
                    .onOpenURL { url in
                        if let id = WidgetDeepLink.todoID(from: url) {
                            deepLinkedTodoID = id
                        }
                    }

                if lock.isLocked {
                    LockScreenView { Task { await lock.authenticate() } }
                }

                if !didOnboard {
                    OnboardingView { didOnboard = true }
                        .background(.background)
                }

                // Apple 로그인 — 온보딩 완료 후, 미로그인 + 아직 건너뛰지 않은 경우
                if didOnboard && !signIn.isSignedIn && !didDismissSignIn {
                    AppleSignInView(controller: signIn) {
                        didDismissSignIn = true  // "로그인 없이 시작" → 다시 묻지 않음
                    }
                    .background(.background)
                    .transition(.opacity)
                }
            }
            // 콜드 스타트 시 1회 인증 (앱은 이미 active로 시작 → onChange 미발생 대비)
            .task { await lock.authenticate() }
            // 모든 시스템 .font() 스케일을 Noteworthy로 교체
            .sketchFontEnvironment()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                let todos = (try? container.mainContext.fetch(FetchDescriptor<TodoItem>())) ?? []
                WidgetSyncing.refresh(from: todos)
                // 활성화될 때만 인증 트리거 (백그라운드 중 보이지 않는 프롬프트 방지)
                Task { await lock.authenticate() }
            case .background:
                lock.relock()
            default: break
            }
        }
        .onChange(of: appLockEnabled) { _, enabled in
            lock.lockEnabled = enabled
        }
    }
}

struct ContentView: View {
    @Binding var deepLinkedTodoID: UUID?
    @ObservedObject var signIn: AppleSignInController

    init(deepLinkedTodoID: Binding<UUID?>, signIn: AppleSignInController) {
        _deepLinkedTodoID = deepLinkedTodoID
        self.signIn = signIn
        // 탭바 + 네비게이션바를 흰 종이 + 검정 잉크 스타일로
        let paper    = UIColor(red: 0.969, green: 0.969, blue: 0.961, alpha: 1)  // #F7F7F5
        let inkColor = UIColor(red: 0.102, green: 0.102, blue: 0.094, alpha: 1)  // #1A1A18
        let divider  = UIColor(red: 0.800, green: 0.800, blue: 0.800, alpha: 1)

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = paper
        // 탭바 라벨도 Noteworthy로 통일
        let tabItem = tabBarAppearance.stackedLayoutAppearance
        tabItem.normal.titleTextAttributes = [
            .font: UIFont(name: "Noteworthy", size: 10) ?? UIFont.systemFont(ofSize: 10)
        ]
        tabItem.selected.titleTextAttributes = [
            .font: UIFont(name: "Noteworthy-Bold", size: 10) ?? UIFont.boldSystemFont(ofSize: 10)
        ]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = inkColor

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = paper
        navAppearance.shadowColor = divider
        navAppearance.titleTextAttributes = [
            .font: UIFont(name: "Noteworthy-Bold", size: 17) ?? UIFont.boldSystemFont(ofSize: 17),
            .foregroundColor: inkColor
        ]
        navAppearance.largeTitleTextAttributes = [
            .font: UIFont(name: "Noteworthy-Bold", size: 32) ?? UIFont.boldSystemFont(ofSize: 32),
            .foregroundColor: inkColor
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = inkColor
    }

    var body: some View {
        TabView {
            NavigationStack {
                TodoListView()
                    // 딥링크로 전달된 투두로 이동 (간단 구현: 알림/배지용 훅 지점)
                    .overlay(alignment: .top) {
                        if deepLinkedTodoID != nil {
                            Color.clear.onAppear { /* 라우팅 연결 지점 */ }
                        }
                    }
            }
            .tabItem { Label("투두", systemImage: "checklist") }

            NavigationStack {
                CalendarFeedView()
            }
            .tabItem { Label("캘린더", systemImage: "calendar") }

            NavigationStack {
                SpaceListView()
            }
            .tabItem { Label("공유방", systemImage: "person.2") }

            NavigationStack {
                TemplateListView()
            }
            .tabItem { Label("템플릿", systemImage: "square.on.square") }

            NavigationStack {
                SettingsView(signIn: signIn)
            }
            .tabItem { Label("설정", systemImage: "gear") }
        }
    }
}
