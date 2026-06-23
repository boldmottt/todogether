import SwiftUI
import SwiftData
import SharedModels
import SpaceFeature
import TodoFeature
import CalendarFeature
import TemplateFeature

@main
struct TodogetherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
