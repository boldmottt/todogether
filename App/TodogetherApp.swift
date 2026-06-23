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

    let container: ModelContainer = try! ModelContainer.makeShared()

    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkedTodoID: $deepLinkedTodoID)
                .currentUser(currentUser)
                .task {
                    NotificationManager.shared.registerCategories()
                    _ = await NotificationManager.shared.requestAuthorization()
                    // TODO: CloudKit userRecordID + iCloud 이름으로 currentUser 채우기
                }
                // 위젯 딥링크 수신 (todogether://todo/<id>)
                .onOpenURL { url in
                    if let id = WidgetDeepLink.todoID(from: url) {
                        deepLinkedTodoID = id
                    }
                }
        }
        .modelContainer(container)
        // 앱이 활성화될 때 위젯 저장소를 최신 투두로 동기화
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                let todos = (try? container.mainContext.fetch(FetchDescriptor<TodoItem>())) ?? []
                WidgetSyncing.refresh(from: todos)
            }
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
        }
    }
}
