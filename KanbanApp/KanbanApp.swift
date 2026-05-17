import SwiftUI
import SwiftData

@main
struct KanbanApp: App {
    let persistence: PersistenceBootstrapResult
    let appStoreScreenshotScene: AppStoreScreenshotScene?

    init() {
        UserDefaults.standard.register(defaults: [
            "isFocusGuardEnabled": true,
            "maxActiveTasks": 3,
            "isTaskAgingNotificationsEnabled": false,
            "taskAgingNotificationDayThreshold": 3,
            "taskStalledNotificationDayThreshold": 5,
            "taskAgingNotificationHour": 9,
        ])

        appStoreScreenshotScene = AppStoreScreenshotScene.fromLaunchArguments()

        if appStoreScreenshotScene != nil {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            UserDefaults.standard.set(true, forKey: "isFocusGuardEnabled")
            UserDefaults.standard.set(3, forKey: "maxActiveTasks")
            UserDefaults.standard.set(4, forKey: "wipLimitHitCount")
            persistence = AppStoreScreenshotFixtures.makeContainer()
        } else {
            persistence = PersistenceBootstrap.makeContainer()
        }
    }

    var body: some Scene {
        WindowGroup {
            if let appStoreScreenshotScene {
                AppStoreScreenshotView(scene: appStoreScreenshotScene)
                    .modelContainer(persistence.container)
                    .environment(\.persistenceSyncMode, persistence.syncMode)
            } else {
                ContentView()
                    .modelContainer(persistence.container)
                    .environment(\.persistenceSyncMode, persistence.syncMode)
            }
        }
    }
}
