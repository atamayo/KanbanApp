import SwiftUI

struct TaskAgingNotificationSyncModifier: ViewModifier {
    let tasks: [TaskItem]

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isTaskAgingNotificationsEnabled") private var isTaskAgingNotificationsEnabled = false
    @AppStorage("taskAgingNotificationDayThreshold") private var taskAgingNotificationDayThreshold = 3
    @AppStorage("taskStalledNotificationDayThreshold") private var taskStalledNotificationDayThreshold = 5
    @AppStorage("taskAgingNotificationHour") private var taskAgingNotificationHour = 9

    private var settings: TaskAgingNotificationSettings {
        TaskAgingNotificationSettings(
            isEnabled: isTaskAgingNotificationsEnabled,
            agingDays: taskAgingNotificationDayThreshold,
            stalledDays: taskStalledNotificationDayThreshold,
            hour: taskAgingNotificationHour
        )
    }

    private var scheduleToken: String {
        let activeTaskSignature = tasks
            .filter { $0.status == .inProgress && !$0.isArchived }
            .map { task in
                [
                    task.id.uuidString,
                    task.title,
                    task.statusRaw,
                    task.priority.rawValue,
                    task.isBlocked.description,
                    task.archivedAt?.timeIntervalSince1970.description ?? "active",
                    task.enteredInProgressAt?.timeIntervalSince1970.description ?? "none",
                    task.lastStatusChange.timeIntervalSince1970.description,
                ].joined(separator: ":")
            }
            .sorted()
            .joined(separator: "|")

        return [
            settings.isEnabled.description,
            settings.agingDays.description,
            settings.normalizedStalledDays.description,
            settings.normalizedHour.description,
            activeTaskSignature,
        ].joined(separator: "#")
    }

    func body(content: Content) -> some View {
        content
            .task(id: scheduleToken) {
                await refreshSchedule()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await refreshSchedule()
                }
            }
    }

    private func refreshSchedule() async {
        await TaskAgingNotificationService.refreshSchedule(
            tasks: tasks,
            settings: settings
        )
    }
}

extension View {
    func syncTaskAgingNotifications(tasks: [TaskItem]) -> some View {
        modifier(TaskAgingNotificationSyncModifier(tasks: tasks))
    }
}
