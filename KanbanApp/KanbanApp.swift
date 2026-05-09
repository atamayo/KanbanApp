import SwiftUI
import SwiftData

@main
struct KanbanApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: TaskItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
