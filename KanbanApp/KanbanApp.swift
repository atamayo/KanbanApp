import SwiftUI
import SwiftData

@main
struct KanbanApp: App {
    let container: ModelContainer

    init() {
        let config = ModelConfiguration()
        do {
            container = try ModelContainer(for: TaskItem.self, configurations: config)
        } catch {
            try? FileManager.default.removeItem(at: config.url)
            container = try! ModelContainer(for: TaskItem.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
