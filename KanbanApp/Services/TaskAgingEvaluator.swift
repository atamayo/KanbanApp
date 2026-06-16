import Foundation

struct TaskAgingSummary {
    let agingTasks: [TaskItem]
    let stalledTasks: [TaskItem]

    var hasTasksNeedingAttention: Bool {
        !agingTasks.isEmpty || !stalledTasks.isEmpty
    }
}

struct ToDoWaitingSummary {
    let staleTasks: [TaskItem]
    let oldestTask: TaskItem?

    var hasStaleTasks: Bool {
        !staleTasks.isEmpty
    }
}

enum TaskAgingEvaluator {
    static let defaultToDoWaitingDays = 7

    static func evaluate(
        tasks: [TaskItem],
        now: Date,
        agingDays: Int,
        stalledDays: Int
    ) -> TaskAgingSummary {
        let agingInterval = TimeInterval(max(agingDays, 1) * 86_400)
        let stalledInterval = TimeInterval(max(stalledDays, agingDays + 1) * 86_400)

        let activeTasks = tasks
            .filter { task in
                task.status == .inProgress &&
                !task.isArchived &&
                !task.isBlocked
            }
            .sorted { lhs, rhs in
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                return activeSince(for: lhs) < activeSince(for: rhs)
            }

        let agingTasks = activeTasks.filter { task in
            let age = now.timeIntervalSince(activeSince(for: task))
            return age >= agingInterval && age < stalledInterval
        }

        let stalledTasks = activeTasks.filter { task in
            now.timeIntervalSince(activeSince(for: task)) >= stalledInterval
        }

        return TaskAgingSummary(
            agingTasks: agingTasks,
            stalledTasks: stalledTasks
        )
    }

    static func evaluateToDoWaiting(
        tasks: [TaskItem],
        now: Date,
        waitingDays: Int = defaultToDoWaitingDays
    ) -> ToDoWaitingSummary {
        let waitingInterval = TimeInterval(max(waitingDays, 1) * 86_400)
        let todoTasks = tasks
            .filter { task in
                task.status == .todo &&
                !task.isArchived
            }
            .sorted { lhs, rhs in
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                return toDoSince(for: lhs) < toDoSince(for: rhs)
            }

        let staleTasks = todoTasks.filter { task in
            now.timeIntervalSince(toDoSince(for: task)) >= waitingInterval
        }
        let oldestTask = todoTasks.min { lhs, rhs in
            toDoSince(for: lhs) < toDoSince(for: rhs)
        }

        return ToDoWaitingSummary(
            staleTasks: staleTasks,
            oldestTask: oldestTask
        )
    }

    static func activeSince(for task: TaskItem) -> Date {
        task.enteredInProgressAt ?? task.lastStatusChange
    }

    static func toDoSince(for task: TaskItem) -> Date {
        task.lastStatusChange
    }

    static func shortDurationText(for interval: TimeInterval) -> String {
        let seconds = max(interval, 0)
        let days = Int(seconds / 86_400)
        if days > 0 {
            return String(localized: "\(days)d", comment: "Short duration in days")
        }

        let hours = Int(seconds / 3_600)
        if hours > 0 {
            return String(localized: "\(hours)h", comment: "Short duration in hours")
        }

        let minutes = Int(seconds / 60)
        if minutes > 0 {
            return String(localized: "\(minutes)m", comment: "Short duration in minutes")
        }

        return String(localized: "now", comment: "Immediate relative duration")
    }
}
