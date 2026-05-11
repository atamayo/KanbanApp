import SwiftUI

#if os(iOS)
import UserNotifications
#endif

struct AppIconBadgeSyncModifier: ViewModifier {
    let tasks: [TaskItem]

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasRequestedBadgePermission") private var hasRequestedBadgePermission = false

    private var inProgressCount: Int {
        tasks.filter { $0.status == .inProgress }.count
    }

    func body(content: Content) -> some View {
        content
            .task {
                await requestBadgePermissionIfNeeded()
                await syncBadgeCount()
            }
            .onChange(of: inProgressCount) { _, _ in
                Task {
                    await syncBadgeCount()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await requestBadgePermissionIfNeeded()
                    await syncBadgeCount()
                }
            }
    }

    private func requestBadgePermissionIfNeeded() async {
#if os(iOS)
        guard !hasRequestedBadgePermission else { return }
        guard inProgressCount > 0 else { return }

        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.badge])) ?? false

        await MainActor.run {
            hasRequestedBadgePermission = true

            if !granted {
                Task {
                    try? await center.setBadgeCount(0)
                }
            }
        }
#endif
    }

    private func syncBadgeCount() async {
#if os(iOS)
        try? await UNUserNotificationCenter.current().setBadgeCount(inProgressCount)
#endif
    }
}

extension View {
    func syncAppIconBadge(tasks: [TaskItem]) -> some View {
        modifier(AppIconBadgeSyncModifier(tasks: tasks))
    }
}
