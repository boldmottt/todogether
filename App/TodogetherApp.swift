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
    @State private var currentUser: CurrentUser = .local
    @State private var deepLinkedTodoID: UUID?
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("didOnboard") private var didOnboard = false
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @StateObject private var lock: AppLockController

    let container: ModelContainer = try! ModelContainer.makeShared()

    init() {
        let enabled = UserDefaults.standard.bool(forKey: "appLockEnabled")
        _lock = StateObject(wrappedValue: AppLockController(lockEnabled: enabled))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(deepLinkedTodoID: $deepLinkedTodoID)
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
            }
            // 콜드 스타트 시 1회 인증 (앱은 이미 active로 시작 → onChange 미발생 대비)
            .task { await lock.authenticate() }
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
                SettingsView()
            }
            .tabItem { Label("설정", systemImage: "gear") }
        }
    }
}
