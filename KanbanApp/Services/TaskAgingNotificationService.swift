import Foundation

#if os(iOS)
import UserNotifications
#endif

struct TaskAgingNotificationSettings: Equatable {
    let isEnabled: Bool
    let agingDays: Int
    let stalledDays: Int
    let hour: Int

    var normalizedStalledDays: Int {
        max(stalledDays, agingDays + 1)
    }

    var normalizedHour: Int {
        min(max(hour, 0), 23)
    }
}

enum TaskAgingNotificationService {
    private static let notificationPrefix = "task-aging-digest"
    private static let scheduledDigestCount = 7

    static func requestAuthorization() async -> Bool {
#if os(iOS)
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
#else
        return false
#endif
    }

    static func refreshSchedule(tasks: [TaskItem], settings: TaskAgingNotificationSettings) async {
#if os(iOS)
        await cancelScheduledNotifications()

        guard settings.isEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let now = Date()
        let calendar = Calendar.current
        let firstDigestDate = nextDigestDate(after: now, hour: settings.normalizedHour, calendar: calendar)

        for offset in 0..<scheduledDigestCount {
            guard let digestDate = calendar.date(byAdding: .day, value: offset, to: firstDigestDate) else {
                continue
            }

            let summary = TaskAgingEvaluator.evaluate(
                tasks: tasks,
                now: digestDate,
                agingDays: settings.agingDays,
                stalledDays: settings.normalizedStalledDays
            )

            guard summary.hasTasksNeedingAttention else { continue }

            let content = UNMutableNotificationContent()
            content.title = title(for: summary)
            content.body = body(for: summary)
            content.sound = .default
            content.categoryIdentifier = "task-aging"
            content.threadIdentifier = notificationPrefix

            let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: digestDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(notificationPrefix)-\(offset)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
#endif
    }

    static func cancelScheduledNotifications() async {
#if os(iOS)
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(notificationPrefix) }

        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
#endif
    }

    private static func nextDigestDate(after now: Date, hour: Int, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = 0
        components.second = 0

        let candidate = calendar.date(from: components) ?? now
        if candidate > now {
            return candidate
        }

        return calendar.date(byAdding: .day, value: 1, to: candidate) ?? now
    }

    private static func title(for summary: TaskAgingSummary) -> String {
        if !summary.stalledTasks.isEmpty {
            let count = summary.stalledTasks.count
            return String(localized: "\(count) \(taskWord(count)) may be stalled", comment: "Daily notification title for stalled active tasks")
        }

        let count = summary.agingTasks.count
        return String(localized: "\(count) active \(taskWord(count)) aging", comment: "Daily notification title for aging active tasks")
    }

    private static func body(for summary: TaskAgingSummary) -> String {
        if let task = summary.stalledTasks.first {
            let agingCount = summary.agingTasks.count
            if agingCount > 0 {
                return String(localized: "\"\(task.title)\" may need a decision. \(agingCount) more active \(taskWord(agingCount)) are aging.", comment: "Daily notification body naming a stalled task and summarizing aging tasks")
            }
            return String(localized: "\"\(task.title)\" has been in progress for a while. Review it before pulling more work.", comment: "Daily notification body naming a stalled task")
        }

        if let task = summary.agingTasks.first {
            return String(localized: "\"\(task.title)\" is starting to age in progress. A quick review can keep the board moving.", comment: "Daily notification body naming an aging task")
        }

        return String(localized: "Review your active tasks and decide what should move forward next.")
    }

    private static func taskWord(_ count: Int) -> String {
        count == 1 ? String(localized: "task", comment: "Singular task count noun") : String(localized: "tasks", comment: "Plural task count noun")
    }
}
