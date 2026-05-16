import Foundation

struct TaskAgingSummary {
    let agingTasks: [TaskItem]
    let stalledTasks: [TaskItem]

    var hasTasksNeedingAttention: Bool {
        !agingTasks.isEmpty || !stalledTasks.isEmpty
    }
}

enum TaskAgingEvaluator {
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

    static func activeSince(for task: TaskItem) -> Date {
        task.enteredInProgressAt ?? task.lastStatusChange
    }
}
