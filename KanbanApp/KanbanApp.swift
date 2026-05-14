import SwiftUI
import SwiftData

@main
struct KanbanApp: App {
    let persistence: PersistenceBootstrapResult

    init() {
        UserDefaults.standard.register(defaults: [
            "isFocusGuardEnabled": true,
            "maxActiveTasks": 3,
        ])

        persistence = PersistenceBootstrap.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(persistence.container)
                .environment(\.persistenceSyncMode, persistence.syncMode)
        }
    }
}
