import SwiftUI
import SwiftData
import SharedModels
import SpaceFeature
import TodoFeature
import CalendarFeature
import TemplateFeature
import NotificationFeature

@main
struct TodogetherApp: App {
    @State private var currentUser: CurrentUser = .local

    var body: some Scene {
        WindowGroup {
            ContentView()
                .currentUser(currentUser)
                .task {
                    NotificationManager.shared.registerCategories()
                    _ = await NotificationManager.shared.requestAuthorization()
                    // TODO: CloudKit userRecordID + iCloud 이름으로 currentUser 채우기
                }
        }
        .modelContainer(try! ModelContainer.makeShared())
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodoListView()
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
