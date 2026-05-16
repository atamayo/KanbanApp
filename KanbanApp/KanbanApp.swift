import SwiftUI
import SwiftData

@main
struct KanbanApp: App {
    let persistence: PersistenceBootstrapResult

    init() {
        UserDefaults.standard.register(defaults: [
            "isFocusGuardEnabled": true,
            "maxActiveTasks": 3,
            "isTaskAgingNotificationsEnabled": false,
            "taskAgingNotificationDayThreshold": 3,
            "taskStalledNotificationDayThreshold": 5,
            "taskAgingNotificationHour": 9,
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
