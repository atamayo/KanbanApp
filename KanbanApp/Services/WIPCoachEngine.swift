import Foundation

enum WIPPressureLevel: Equatable {
    case hasRoom
    case healthy
    case nearLimit
    case atLimit
    case overloaded
    case blocked
}

enum WIPCoachActionType: Equatable {
    case pullNextTask
    case focusCurrentTask
    case unblockTask
    case reduceWIP
    case breakDownTask
    case noActionNeeded
}

struct WIPCoachStats {
    let activeCount: Int
    let wipLimit: Int
    let slotsLeft: Int
    let blockedCount: Int
    let readyCount: Int
}

struct WIPCoachTaskCandidate {
    let task: TaskItem
    let score: Int
    let reason: String
}

struct WIPCoachRecommendation {
    let pressure: WIPPressureLevel
    let action: WIPCoachActionType
    let headline: String
    let body: String
    let ctaTitle: String
    let label: String
    let recommendedTask: TaskItem?
    let reason: String
    let stats: WIPCoachStats
    let readyAlternatives: [WIPCoachTaskCandidate]
    let activeTasks: [TaskItem]
}

enum WIPCoachEngine {
    static func evaluate(
        tasks: [TaskItem],
        maxActiveTasks: Int,
        isFocusGuardEnabled: Bool,
        now: Date = Date()
    ) -> WIPCoachRecommendation {
        let wipLimit = max(maxActiveTasks, 1)
        let activeTasks = tasks
            .filter { $0.status == .inProgress }
            .sorted { activeSortKey($0, now: now) > activeSortKey($1, now: now) }
        let readyTasks = tasks
            .filter { $0.status == .todo && !$0.isBlocked }
            .sorted { $0.order < $1.order }
        let blockedTasks = activeTasks
            .filter(\.isBlocked)
            .sorted { activeSortKey($0, now: now) > activeSortKey($1, now: now) }
        let rankedReadyTasks = readyTasks
            .map { readyCandidate(for: $0, activeTasks: activeTasks, now: now) }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                if lhs.task.priority.sortOrder != rhs.task.priority.sortOrder {
                    return lhs.task.priority.sortOrder < rhs.task.priority.sortOrder
                }
                return lhs.task.createdAt < rhs.task.createdAt
            }

        let activeCount = activeTasks.count
        let slotsLeft = max(wipLimit - activeCount, 0)
        let stats = WIPCoachStats(
            activeCount: activeCount,
            wipLimit: wipLimit,
            slotsLeft: slotsLeft,
            blockedCount: blockedTasks.count,
            readyCount: readyTasks.count
        )

        if isFocusGuardEnabled && activeCount > wipLimit {
            return recommendation(
                pressure: .overloaded,
                action: .reduceWIP,
                recommendedTask: bestActiveTask(from: activeTasks, now: now),
                reason: "Over WIP limit by \(activeCount - wipLimit)",
                stats: stats,
                readyAlternatives: Array(rankedReadyTasks.prefix(3)),
                activeTasks: activeTasks
            )
        }

        if let blockedTask = blockedTasks.first {
            return recommendation(
                pressure: .blocked,
                action: .unblockTask,
                recommendedTask: blockedTask,
                reason: "Blocked active work",
                stats: stats,
                readyAlternatives: Array(rankedReadyTasks.prefix(3)),
                activeTasks: activeTasks
            )
        }

        if isFocusGuardEnabled && activeCount >= wipLimit {
            return recommendation(
                pressure: .atLimit,
                action: .focusCurrentTask,
                recommendedTask: bestActiveTask(from: activeTasks, now: now),
                reason: "WIP limit reached",
                stats: stats,
                readyAlternatives: Array(rankedReadyTasks.prefix(3)),
                activeTasks: activeTasks
            )
        }

        if isFocusGuardEnabled, activeCount == wipLimit - 1, activeCount > 0 {
            if let bestReady = rankedReadyTasks.first, bestReady.score >= 55 {
                return recommendation(
                    pressure: .nearLimit,
                    action: .pullNextTask,
                    recommendedTask: bestReady.task,
                    reason: bestReady.reason,
                    stats: stats,
                    readyAlternatives: Array(rankedReadyTasks.prefix(3)),
                    activeTasks: activeTasks
                )
            }

            return recommendation(
                pressure: .nearLimit,
                action: .focusCurrentTask,
                recommendedTask: bestActiveTask(from: activeTasks, now: now),
                reason: "Only one focus slot remains",
                stats: stats,
                readyAlternatives: Array(rankedReadyTasks.prefix(3)),
                activeTasks: activeTasks
            )
        }

        if let bestReady = rankedReadyTasks.first {
            return recommendation(
                pressure: activeCount == 0 ? .hasRoom : .healthy,
                action: .pullNextTask,
                recommendedTask: bestReady.task,
                reason: bestReady.reason,
                stats: stats,
                readyAlternatives: Array(rankedReadyTasks.prefix(3)),
                activeTasks: activeTasks
            )
        }

        return recommendation(
            pressure: .healthy,
            action: .noActionNeeded,
            recommendedTask: nil,
            reason: activeTasks.isEmpty ? "No ready work needs attention" : "No ready tasks are waiting",
            stats: stats,
            readyAlternatives: [],
            activeTasks: activeTasks
        )
    }

    private static func recommendation(
        pressure: WIPPressureLevel,
        action: WIPCoachActionType,
        recommendedTask: TaskItem?,
        reason: String,
        stats: WIPCoachStats,
        readyAlternatives: [WIPCoachTaskCandidate],
        activeTasks: [TaskItem]
    ) -> WIPCoachRecommendation {
        let copy = copy(for: pressure)
        return WIPCoachRecommendation(
            pressure: pressure,
            action: action,
            headline: copy.headline,
            body: copy.body,
            ctaTitle: copy.ctaTitle,
            label: label(for: action),
            recommendedTask: recommendedTask,
            reason: reason,
            stats: stats,
            readyAlternatives: readyAlternatives,
            activeTasks: activeTasks
        )
    }

    private static func copy(for pressure: WIPPressureLevel) -> (headline: String, body: String, ctaTitle: String) {
        switch pressure {
        case .hasRoom:
            return (
                "Your flow still has room.",
                "You can safely pull one more task, but keep active work tight so current tasks can reach done.",
                "Review Before Pulling"
            )
        case .healthy:
            return (
                "Your flow is balanced.",
                "Your active work is within capacity. Pull carefully or finish a current task first.",
                "Choose Next Task"
            )
        case .nearLimit:
            return (
                "You're close to your WIP limit.",
                "Pull only if the next task is small or urgent. Otherwise, finish active work first.",
                "Review Capacity"
            )
        case .atLimit:
            return (
                "You're at capacity.",
                "Finish or move one active task forward before pulling new work.",
                "Focus Current Work"
            )
        case .overloaded:
            return (
                "Too much work is active.",
                "Reduce active work before starting anything new. This will protect focus and completion speed.",
                "Reduce WIP Now"
            )
        case .blocked:
            return (
                "Blocked work is slowing your flow.",
                "Resolve blocked work before pulling more tasks, unless a new task is urgent and small.",
                "Unblock Work"
            )
        }
    }

    private static func label(for action: WIPCoachActionType) -> String {
        switch action {
        case .pullNextTask:
            return "BEST TASK TO PULL NEXT"
        case .focusCurrentTask:
            return "FOCUS THIS TASK"
        case .unblockTask:
            return "UNBLOCK FIRST"
        case .reduceWIP:
            return "REDUCE WIP FIRST"
        case .breakDownTask:
            return "BREAK DOWN FIRST"
        case .noActionNeeded:
            return "NO ACTION NEEDED"
        }
    }

    private static func readyCandidate(for task: TaskItem, activeTasks: [TaskItem], now: Date) -> WIPCoachTaskCandidate {
        var score = 0
        var reasons: [String] = []

        switch task.priority {
        case .high:
            score += 40
            reasons.append("High priority")
        case .medium:
            score += 20
            reasons.append("Medium priority")
        case .low:
            score += 5
            reasons.append("Low priority")
        }

        if !task.completionCriteria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            score += 10
            reasons.append("Clear finish check")
        }

        if task.desc.trimmingCharacters(in: .whitespacesAndNewlines).count >= 24 {
            score += 5
            reasons.append("Enough context")
        }

        let ageDays = now.timeIntervalSince(task.createdAt) / 86_400
        if ageDays >= 7 {
            score += 5
            reasons.append("Waiting for a week")
        } else if ageDays >= 3 {
            score += 3
            reasons.append("Waiting for days")
        }

        let titleWordCount = task.title
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .count
        if titleWordCount <= 2 &&
            task.desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            task.completionCriteria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            score -= 15
            reasons.append("Needs clearer scope")
        }

        if task.title.count > 90 {
            score -= 10
            reasons.append("Large task")
        }

        if activeTasks.contains(where: { $0.title.localizedCaseInsensitiveContains(task.title) || task.title.localizedCaseInsensitiveContains($0.title) }) {
            score += 10
            reasons.append("Related to active work")
        }

        return WIPCoachTaskCandidate(
            task: task,
            score: score,
            reason: reasons.first ?? "Ready to pull"
        )
    }

    private static func bestActiveTask(from tasks: [TaskItem], now: Date) -> TaskItem? {
        tasks.sorted { activeSortKey($0, now: now) > activeSortKey($1, now: now) }.first
    }

    private static func activeSortKey(_ task: TaskItem, now: Date) -> Int {
        let ageDays = Int(now.timeIntervalSince(task.lastStatusChange) / 86_400)
        let priorityScore: Int
        switch task.priority {
        case .high: priorityScore = 40
        case .medium: priorityScore = 20
        case .low: priorityScore = 5
        }

        return (task.isBlocked ? 1_000 : 0) + priorityScore + min(ageDays * 4, 80)
    }
}
