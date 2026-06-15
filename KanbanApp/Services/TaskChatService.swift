import Foundation
import FoundationModels

@Generable
struct TaskChatAnswerDraft {
    @Guide(description: "A direct answer to the user's task question. Use only the supplied board facts and exact metric values.")
    var answer: String

    @Guide(description: "A compact factual summary of the metric used. Leave empty if the answer is not metric-based.")
    var metricSummary: String

    @Guide(description: "Comma-separated task UUIDs for tasks directly referenced in the answer. Use only UUIDs from the supplied board facts. Leave empty if none.")
    var referencedTaskIDs: String

    @Guide(description: "At most two proposed actions, one per line, using exact format: actionKind|taskUUID|short task title|confirmation label|optional payload. Leave empty if no safe action fits.")
    var proposedActions: String
}

struct TaskChatResponse {
    let answer: String
    let metricSummary: String
    let referencedTaskIDs: [UUID]
    let proposedActions: [TaskChatProposedAction]
    let visualizations: [TaskChatVisualization]
    let evidence: TaskChatEvidence?
}

enum TaskChatVisualizationKind: String, CaseIterable {
    case statusBreakdown
    case priorityBreakdown
    case activeAging
    case completedThisMonth
    case slowestClosed
    case blockedTasks
    case throughputTrend
    case closeTimeTrend
    case weekComparison
    case monthComparison
    case priorityCloseTime

    static var promptList: String {
        allCases.map(\.rawValue).joined(separator: ", ")
    }
}

enum TaskChatVisualizationTint: String, Equatable {
    case todo
    case inProgress
    case done
    case high
    case medium
    case low
    case blocked
    case neutral
}

struct TaskChatMetricCard: Identifiable, Equatable {
    let id: UUID
    let label: String
    let value: String
    let systemImage: String
    let tint: TaskChatVisualizationTint

    init(
        id: UUID = UUID(),
        label: String,
        value: String,
        systemImage: String,
        tint: TaskChatVisualizationTint
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.systemImage = systemImage
        self.tint = tint
    }
}

struct TaskChatBar: Identifiable, Equatable {
    let id: UUID
    let label: String
    let value: Double
    let displayValue: String
    let tint: TaskChatVisualizationTint

    init(
        id: UUID = UUID(),
        label: String,
        value: Double,
        displayValue: String,
        tint: TaskChatVisualizationTint
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.displayValue = displayValue
        self.tint = tint
    }
}

struct TaskChatTable: Equatable {
    let columns: [String]
    let rows: [TaskChatTableRow]
}

struct TaskChatTableRow: Identifiable, Equatable {
    let id: UUID
    let values: [String]
    let taskID: UUID?

    init(id: UUID = UUID(), values: [String], taskID: UUID? = nil) {
        self.id = id
        self.values = values
        self.taskID = taskID
    }
}

struct TaskChatVisualization: Identifiable, Equatable {
    let id: UUID
    let kind: TaskChatVisualizationKind
    let title: String
    let subtitle: String
    let metricCards: [TaskChatMetricCard]
    let bars: [TaskChatBar]
    let table: TaskChatTable?

    init(
        id: UUID = UUID(),
        kind: TaskChatVisualizationKind,
        title: String,
        subtitle: String,
        metricCards: [TaskChatMetricCard] = [],
        bars: [TaskChatBar] = [],
        table: TaskChatTable? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.metricCards = metricCards
        self.bars = bars
        self.table = table
    }
}

struct TaskChatEvidenceRow: Identifiable, Equatable {
    let id: UUID
    let label: String
    let value: String

    init(id: UUID = UUID(), label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }
}

struct TaskChatEvidence: Identifiable, Equatable {
    let id: UUID
    let rows: [TaskChatEvidenceRow]
    let includedTaskIDs: [UUID]

    init(id: UUID = UUID(), rows: [TaskChatEvidenceRow], includedTaskIDs: [UUID]) {
        self.id = id
        self.rows = rows
        self.includedTaskIDs = includedTaskIDs
    }
}

enum TaskChatActionKind: String, CaseIterable {
    case openTask
    case addNextAction
    case markBlocked
    case markActive
    case moveToTodo
    case moveToInProgress
    case markDone
    case archiveDoneTask

    static var promptList: String {
        allCases
            .filter { $0 != .addNextAction }
            .map(\.rawValue)
            .joined(separator: ", ")
    }

    var fallbackConfirmationLabel: String {
        switch self {
        case .openTask:
            return String(localized: "Open Task")
        case .addNextAction:
            return String(localized: "Add Next Action")
        case .markBlocked:
            return String(localized: "Mark Blocked")
        case .markActive:
            return String(localized: "Mark Active")
        case .moveToTodo:
            return String(localized: "Move to To Do")
        case .moveToInProgress:
            return String(localized: "Move to In Progress")
        case .markDone:
            return String(localized: "Mark Done")
        case .archiveDoneTask:
            return String(localized: "Archive Completed Task")
        }
    }
}

struct TaskChatProposedAction: Identifiable, Equatable {
    let id: UUID
    let kind: TaskChatActionKind
    let taskID: UUID
    let taskTitle: String
    let confirmationLabel: String
    let payload: String

    init(
        id: UUID = UUID(),
        kind: TaskChatActionKind,
        taskID: UUID,
        taskTitle: String,
        confirmationLabel: String,
        payload: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.taskID = taskID
        self.taskTitle = taskTitle
        self.confirmationLabel = confirmationLabel
        self.payload = payload
    }
}

struct TaskChatTurn {
    let role: String
    let content: String
}

struct TaskChatRequest {
    let question: String
    let previousTurns: [TaskChatTurn]
    let snapshot: TaskChatBoardSnapshot
    let responseLanguageName: String

    init(question: String, previousTurns: [TaskChatTurn], tasks: [TaskItem], now: Date = Date(), locale: Locale = .autoupdatingCurrent) {
        self.question = question
        self.previousTurns = previousTurns
        self.snapshot = TaskChatBoardSnapshot(tasks: tasks, now: now)
        self.responseLanguageName = locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
    }

    var prompt: String {
        """
        User question:
        \(question)

        Recent chat:
        \(previousTurns.isEmpty ? "None" : previousTurns.map { "\($0.role): \($0.content)" }.joined(separator: "\n"))

        Response language:
        \(responseLanguageName)

        Board facts:
        \(snapshot.promptSummary)

        Answer requirements:
        - Answer the current user question directly.
        - Treat the board facts and deterministic metrics as authoritative.
        - Use exact counts, task titles, dates, and durations from the facts.
        - If the facts do not contain enough information, say what is missing.
        - Write the answer and metric summary in the response language unless the user clearly asks in another language. Keep task titles exactly as written.
        - Do not invent tasks, dates, estimates, owners, labels, or status history.
        - Put UUIDs only in referencedTaskIDs. Never include UUIDs in answer or metricSummary.
        - Include referencedTaskIDs only for tasks directly named or clearly discussed in the answer.
        - Leave proposedActions empty unless the current user explicitly asks you to open, move, mark, archive, block, or unblock one specific task.
        - proposedActions actionKind must be one of: \(TaskChatActionKind.promptList).
        - proposedActions format must be exactly: actionKind|taskUUID|short task title|confirmation label.
        - proposedActions payload must be empty.
        - Do not propose create, delete, add-next-action, bulk, or multi-step actions.
        - Do not propose actions for metrics, analysis, recommendations, follow-up suggestions, tables, charts, lists, rankings, or "what should I do" questions.
        - Do not say an action has already happened. The user must confirm actions.
        - Do not add table or chart data to the answer. The app renders focused visuals separately only when the user explicitly asks for a table, chart, graph, ranking, breakdown, list, or comparison.
        - Keep the answer concise and natural.
        """
    }
}

struct TaskChatBoardSnapshot {
    let promptSummary: String
    private let visualizationsByKind: [TaskChatVisualizationKind: TaskChatVisualization]
    private let now: Date
    private let monthStart: Date
    private let monthEnd: Date
    private let previousMonthStart: Date
    private let doneThisWeekStart: Date
    private let weekStart: Date
    private let previousWeekStart: Date
    private let currentTasks: [TaskItem]
    private let visibleDoneTasks: [TaskItem]
    private let archivedDoneTasks: [TaskItem]
    private let completedTasks: [CompletedTaskFact]
    private let doneThisMonth: [CompletedTaskFact]
    private let doneLastMonth: [CompletedTaskFact]
    private let doneThisWeek: [CompletedTaskFact]
    private let doneLastWeek: [CompletedTaskFact]
    private let blockedTasks: [TaskItem]
    private let longestToClose: CompletedTaskFact?
    private let averageCloseDuration: TimeInterval?

    init(tasks: [TaskItem], now: Date = Date(), calendar: Calendar = .current) {
        let completedTasks = tasks
            .compactMap { CompletedTaskFact(task: $0) }
            .sorted { $0.closedAt > $1.closedAt }
        let currentTasks = tasks
            .filter { !$0.isArchived && $0.status != .done }
            .sorted { lhs, rhs in
                if lhs.status.sortOrder != rhs.status.sortOrder {
                    return lhs.status.sortOrder < rhs.status.sortOrder
                }
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                return lhs.createdAt < rhs.createdAt
            }
        let visibleDoneTasks = tasks.filter { $0.status == .done && !$0.isArchived }
        let archivedDoneTasks = tasks.filter { $0.status == .done && $0.isArchived }
        let monthInterval = calendar.dateInterval(of: .month, for: now)
        let monthStart = monthInterval?.start ?? now
        let monthEnd = monthInterval?.end ?? now
        let doneThisMonth = completedTasks.filter { $0.closedAt >= monthStart && $0.closedAt < monthEnd && $0.closedAt <= now }
        let doneThisWeekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let doneThisWeek = completedTasks.filter { $0.closedAt >= doneThisWeekStart && $0.closedAt <= now }
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        let weekStart = weekInterval?.start ?? doneThisWeekStart
        let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? weekStart
        let doneLastWeek = completedTasks.filter { $0.closedAt >= previousWeekStart && $0.closedAt < weekStart }
        let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        let doneLastMonth = completedTasks.filter { $0.closedAt >= previousMonthStart && $0.closedAt < monthStart }
        let weeklyBuckets = Self.weeklyBuckets(completedTasks: completedTasks, now: now, calendar: calendar)
        let longestToClose = completedTasks.max { $0.duration < $1.duration }
        let averageCloseDuration = completedTasks.isEmpty
            ? nil
            : completedTasks.map(\.duration).reduce(0, +) / Double(completedTasks.count)
        let blockedTasks = tasks.filter { !$0.isArchived && $0.status == .inProgress && $0.isBlocked }

        self.now = now
        self.monthStart = monthStart
        self.monthEnd = monthEnd
        self.previousMonthStart = previousMonthStart
        self.doneThisWeekStart = doneThisWeekStart
        self.weekStart = weekStart
        self.previousWeekStart = previousWeekStart
        self.currentTasks = currentTasks
        self.visibleDoneTasks = visibleDoneTasks
        self.archivedDoneTasks = archivedDoneTasks
        self.completedTasks = completedTasks
        self.doneThisMonth = doneThisMonth
        self.doneLastMonth = doneLastMonth
        self.doneThisWeek = doneThisWeek
        self.doneLastWeek = doneLastWeek
        self.blockedTasks = blockedTasks
        self.longestToClose = longestToClose
        self.averageCloseDuration = averageCloseDuration

        self.visualizationsByKind = Self.makeVisualizations(
            tasks: tasks,
            currentTasks: currentTasks,
            visibleDoneTasks: visibleDoneTasks,
            archivedDoneTasks: archivedDoneTasks,
            completedTasks: completedTasks,
            doneThisMonth: doneThisMonth,
            doneLastMonth: doneLastMonth,
            doneThisWeek: doneThisWeek,
            doneLastWeek: doneLastWeek,
            blockedTasks: blockedTasks,
            weeklyBuckets: weeklyBuckets,
            averageCloseDuration: averageCloseDuration,
            longestToClose: longestToClose,
            monthText: Self.monthText(now),
            now: now
        )

        let currentTaskLines = currentTasks
            .prefix(Self.currentTaskLimit)
            .map { Self.currentTaskLine(for: $0, now: now) }
        let completedTaskLines = completedTasks
            .prefix(Self.completedTaskLimit)
            .map(\.promptLine)

        let omittedCurrentCount = max(currentTasks.count - Self.currentTaskLimit, 0)
        let omittedCompletedCount = max(completedTasks.count - Self.completedTaskLimit, 0)

        self.promptSummary = """
        Generated at: \(Self.dateTimeText(now))

        Definitions:
        - Closed tasks are tasks currently in Done, including archived Done tasks.
        - Closed date is finalizedAt when present, otherwise updatedAt.
        - Time to close means createdAt to closed date.
        - This month is \(Self.dateText(monthStart)) through \(Self.dateText(calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? monthEnd)).

        Deterministic metrics:
        - Current visible tasks: \(currentTasks.count + visibleDoneTasks.count)
        - To Do: \(tasks.filter { !$0.isArchived && $0.status == .todo }.count)
        - In Progress: \(tasks.filter { !$0.isArchived && $0.status == .inProgress }.count)
        - Done visible: \(visibleDoneTasks.count)
        - Done archived: \(archivedDoneTasks.count)
        - Completed history total: \(completedTasks.count)
        - Closed this month (\(Self.monthText(now))): \(doneThisMonth.count)
        - Closed last month: \(doneLastMonth.count)
        - Closed in the last 7 days: \(doneThisWeek.count)
        - Closed this week: \(doneThisWeek.count)
        - Closed last week: \(doneLastWeek.count)
        - Week-over-week throughput change: \(Self.signedCount(doneThisWeek.count - doneLastWeek.count))
        - Average close time this week: \(Self.averageDuration(doneThisWeek).map(Self.durationText) ?? "No completed tasks with close dates.")
        - Average close time last week: \(Self.averageDuration(doneLastWeek).map(Self.durationText) ?? "No completed tasks with close dates.")
        - Month-over-month throughput change: \(Self.signedCount(doneThisMonth.count - doneLastMonth.count))
        - Blocked active tasks: \(blockedTasks.count)
        - Longest time to close: \(longestToClose?.metricLine ?? "No completed tasks with close dates.")
        - Average time to close: \(averageCloseDuration.map(Self.durationText) ?? "No completed tasks with close dates.")
        - Weekly throughput trend: \(Self.weeklyThroughputPromptLine(weeklyBuckets))
        - Weekly average close time trend: \(Self.weeklyCloseTimePromptLine(weeklyBuckets))
        - Average close time by priority: \(Self.priorityCloseTimePromptLine(completedTasks))

        Current tasks:
        \(currentTaskLines.isEmpty ? "None" : currentTaskLines.joined(separator: "\n"))
        \(omittedCurrentCount > 0 ? "Omitted current tasks: \(omittedCurrentCount)" : "")

        Completed tasks:
        \(completedTaskLines.isEmpty ? "None" : completedTaskLines.joined(separator: "\n"))
        \(omittedCompletedCount > 0 ? "Omitted completed tasks: \(omittedCompletedCount)" : "")
        """
    }

    func visualizations(for kinds: [TaskChatVisualizationKind]) -> [TaskChatVisualization] {
        kinds.compactMap { visualizationsByKind[$0] }
    }

    func evidence(for question: String, metricSummary: String) -> TaskChatEvidence? {
        let text = question.evidenceSearchText
        guard !text.isEmpty else { return nil }

        if containsAny(text, ["compare", "versus", "vs"]) {
            if text.contains("month") {
                let ids = taskIDs(doneThisMonth) + taskIDs(doneLastMonth)
                return makeEvidence(
                    metricSummary: metricSummary,
                    dateRange: "\(Self.dateRangeText(from: previousMonthStart, through: dayBefore(monthStart))) / \(Self.dateRangeText(from: monthStart, through: now))",
                    countLabel: String(localized: "Tasks counted"),
                    countValue: ids.count.formatted(),
                    excludedSummary: String(localized: "Tasks outside the compared periods."),
                    includedTaskIDs: ids,
                    extraRows: [
                        (String(localized: "This month"), doneThisMonth.count.formatted()),
                        (String(localized: "Last month"), doneLastMonth.count.formatted()),
                        (String(localized: "Change"), Self.signedCount(doneThisMonth.count - doneLastMonth.count))
                    ]
                )
            }

            if text.contains("week") {
                let ids = taskIDs(doneThisWeek) + taskIDs(doneLastWeek)
                return makeEvidence(
                    metricSummary: metricSummary,
                    dateRange: "\(Self.dateRangeText(from: previousWeekStart, through: dayBefore(weekStart))) / \(Self.dateRangeText(from: doneThisWeekStart, through: now))",
                    countLabel: String(localized: "Tasks counted"),
                    countValue: ids.count.formatted(),
                    excludedSummary: String(localized: "Tasks outside the compared periods."),
                    includedTaskIDs: ids,
                    extraRows: [
                        (String(localized: "This week"), doneThisWeek.count.formatted()),
                        (String(localized: "Last week"), doneLastWeek.count.formatted()),
                        (String(localized: "Change"), Self.signedCount(doneThisWeek.count - doneLastWeek.count))
                    ]
                )
            }
        }

        if containsAny(text, ["last 7", "past 7", "last seven", "past seven"]) {
            return completedEvidence(
                tasks: doneThisWeek,
                metricSummary: metricSummary,
                dateRange: Self.dateRangeText(from: doneThisWeekStart, through: now),
                excludedSummary: String(localized: "Tasks outside this date range.")
            )
        }

        if text.contains("last month") {
            return completedEvidence(
                tasks: doneLastMonth,
                metricSummary: metricSummary,
                dateRange: Self.dateRangeText(from: previousMonthStart, through: dayBefore(monthStart)),
                excludedSummary: String(localized: "Tasks outside this date range.")
            )
        }

        if text.contains("this month") || (text.contains("month") && containsAny(text, ["closed", "completed", "done"])) {
            return completedEvidence(
                tasks: doneThisMonth,
                metricSummary: metricSummary,
                dateRange: Self.dateRangeText(from: monthStart, through: now),
                excludedSummary: String(localized: "Tasks outside this date range.")
            )
        }

        if text.contains("last week") {
            return completedEvidence(
                tasks: doneLastWeek,
                metricSummary: metricSummary,
                dateRange: Self.dateRangeText(from: previousWeekStart, through: dayBefore(weekStart)),
                excludedSummary: String(localized: "Tasks outside this date range.")
            )
        }

        if containsAny(text, ["longest", "slowest", "took longer", "took longest", "longer to close"]) {
            return longestCloseEvidence(metricSummary: metricSummary)
        }

        if containsAny(text, ["average close", "close time", "cycle time", "time to close"]) {
            return makeEvidence(
                metricSummary: metricSummary,
                dateRange: String(localized: "All completed history"),
                countLabel: String(localized: "Tasks considered"),
                countValue: completedTasks.count.formatted(),
                excludedSummary: String(localized: "Open tasks and tasks without valid close dates."),
                includedTaskIDs: taskIDs(completedTasks),
                extraRows: [
                    (String(localized: "Average"), averageCloseDuration.map(Self.durationText) ?? String(localized: "None"))
                ]
            )
        }

        if text.contains("blocked") {
            return makeEvidence(
                metricSummary: metricSummary,
                dateRange: nil,
                countLabel: String(localized: "Tasks counted"),
                countValue: blockedTasks.count.formatted(),
                excludedSummary: String(localized: "Archived and completed tasks."),
                includedTaskIDs: taskIDs(blockedTasks)
            )
        }

        if containsAny(text, ["active", "in progress", "progress", "wip", "oldest"]) {
            let activeTasks = currentTasks.filter { $0.status == .inProgress }
            return makeEvidence(
                metricSummary: metricSummary,
                dateRange: nil,
                countLabel: String(localized: "Tasks counted"),
                countValue: activeTasks.count.formatted(),
                excludedSummary: String(localized: "Archived and completed tasks."),
                includedTaskIDs: taskIDs(activeTasks)
            )
        }

        if containsAny(text, ["status", "board"]) {
            let visibleTasks = currentTasks + visibleDoneTasks
            return makeEvidence(
                metricSummary: metricSummary,
                dateRange: nil,
                countLabel: String(localized: "Tasks counted"),
                countValue: visibleTasks.count.formatted(),
                excludedSummary: String(localized: "Archived tasks."),
                includedTaskIDs: taskIDs(visibleTasks)
            )
        }

        return metricSummary.isEmpty ? nil : makeEvidence(
            metricSummary: metricSummary,
            dateRange: nil,
            countLabel: nil,
            countValue: nil,
            excludedSummary: nil,
            includedTaskIDs: []
        )
    }

    private func completedEvidence(
        tasks: [CompletedTaskFact],
        metricSummary: String,
        dateRange: String,
        excludedSummary: String
    ) -> TaskChatEvidence? {
        makeEvidence(
            metricSummary: metricSummary,
            dateRange: dateRange,
            countLabel: String(localized: "Tasks counted"),
            countValue: tasks.count.formatted(),
            excludedSummary: excludedSummary,
            includedTaskIDs: taskIDs(tasks)
        )
    }

    private func longestCloseEvidence(metricSummary: String) -> TaskChatEvidence? {
        let includedIDs = longestToClose.map { [$0.id] } ?? []

        return makeEvidence(
            metricSummary: metricSummary,
            dateRange: String(localized: "All completed history"),
            countLabel: String(localized: "Tasks considered"),
            countValue: completedTasks.count.formatted(),
            excludedSummary: String(localized: "Open tasks and tasks without valid close dates."),
            includedTaskIDs: includedIDs,
            extraRows: [
                (String(localized: "Longest"), longestToClose.map { Self.durationText($0.duration) } ?? String(localized: "None"))
            ]
        )
    }

    private func makeEvidence(
        metricSummary: String,
        dateRange: String?,
        countLabel: String?,
        countValue: String?,
        excludedSummary: String?,
        includedTaskIDs: [UUID],
        extraRows: [(label: String, value: String)] = []
    ) -> TaskChatEvidence? {
        var rows: [(label: String, value: String)] = []
        let metric = metricSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !metric.isEmpty {
            rows.append((String(localized: "Metric"), metric))
        }
        if let dateRange, !dateRange.isEmpty {
            rows.append((String(localized: "Date range"), dateRange))
        }
        if let countLabel, let countValue {
            rows.append((countLabel, countValue))
        }
        rows.append(contentsOf: extraRows.filter { !$0.value.isEmpty })
        if let excludedSummary, !excludedSummary.isEmpty {
            rows.append((String(localized: "Excluded"), excludedSummary))
        }

        let uniqueTaskIDs = includedTaskIDs.uniquePreservingOrder()
        guard !rows.isEmpty || !uniqueTaskIDs.isEmpty else { return nil }

        return TaskChatEvidence(
            rows: rows.map { TaskChatEvidenceRow(label: $0.label, value: $0.value) },
            includedTaskIDs: uniqueTaskIDs
        )
    }

    private func taskIDs(_ tasks: [TaskItem]) -> [UUID] {
        tasks.map(\.id)
    }

    private func taskIDs(_ tasks: [CompletedTaskFact]) -> [UUID] {
        tasks.map(\.id)
    }

    private func dayBefore(_ date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
    }

    private func containsAny(_ text: String, _ values: [String]) -> Bool {
        values.contains { text.contains($0) }
    }

    private static func dateRangeText(from start: Date, through end: Date) -> String {
        "\(dateText(start)) - \(dateText(end))"
    }

    private static let currentTaskLimit = 60
    private static let completedTaskLimit = 80

    private static func makeVisualizations(
        tasks: [TaskItem],
        currentTasks: [TaskItem],
        visibleDoneTasks: [TaskItem],
        archivedDoneTasks: [TaskItem],
        completedTasks: [CompletedTaskFact],
        doneThisMonth: [CompletedTaskFact],
        doneLastMonth: [CompletedTaskFact],
        doneThisWeek: [CompletedTaskFact],
        doneLastWeek: [CompletedTaskFact],
        blockedTasks: [TaskItem],
        weeklyBuckets: [TaskChatTimeBucket],
        averageCloseDuration: TimeInterval?,
        longestToClose: CompletedTaskFact?,
        monthText: String,
        now: Date
    ) -> [TaskChatVisualizationKind: TaskChatVisualization] {
        [
            .statusBreakdown: statusBreakdownVisualization(
                tasks: tasks,
                visibleDoneTasks: visibleDoneTasks,
                archivedDoneTasks: archivedDoneTasks,
                blockedTasks: blockedTasks,
                completedTasks: completedTasks
            ),
            .priorityBreakdown: priorityBreakdownVisualization(tasks: tasks),
            .activeAging: activeAgingVisualization(tasks: currentTasks, now: now),
            .completedThisMonth: completedThisMonthVisualization(tasks: doneThisMonth, monthText: monthText),
            .slowestClosed: slowestClosedVisualization(
                tasks: completedTasks,
                averageCloseDuration: averageCloseDuration,
                longestToClose: longestToClose
            ),
            .blockedTasks: blockedTasksVisualization(tasks: blockedTasks, now: now),
            .throughputTrend: throughputTrendVisualization(buckets: weeklyBuckets),
            .closeTimeTrend: closeTimeTrendVisualization(buckets: weeklyBuckets),
            .weekComparison: periodComparisonVisualization(
                kind: .weekComparison,
                title: String(localized: "This Week vs Last Week"),
                currentLabel: String(localized: "This week"),
                previousLabel: String(localized: "Last week"),
                currentTasks: doneThisWeek,
                previousTasks: doneLastWeek
            ),
            .monthComparison: periodComparisonVisualization(
                kind: .monthComparison,
                title: String(localized: "This Month vs Last Month"),
                currentLabel: String(localized: "This month"),
                previousLabel: String(localized: "Last month"),
                currentTasks: doneThisMonth,
                previousTasks: doneLastMonth
            ),
            .priorityCloseTime: priorityCloseTimeVisualization(tasks: completedTasks)
        ]
    }

    private static func statusBreakdownVisualization(
        tasks: [TaskItem],
        visibleDoneTasks: [TaskItem],
        archivedDoneTasks: [TaskItem],
        blockedTasks: [TaskItem],
        completedTasks: [CompletedTaskFact]
    ) -> TaskChatVisualization {
        let todoCount = tasks.filter { !$0.isArchived && $0.status == .todo }.count
        let inProgressCount = tasks.filter { !$0.isArchived && $0.status == .inProgress }.count
        let doneVisibleCount = visibleDoneTasks.count
        let archivedDoneCount = archivedDoneTasks.count
        let visibleCount = todoCount + inProgressCount + doneVisibleCount

        return TaskChatVisualization(
            kind: .statusBreakdown,
            title: String(localized: "Status Breakdown"),
            subtitle: String(localized: "\(visibleCount.formatted()) visible tasks, \(archivedDoneCount.formatted()) archived completed"),
            metricCards: [
                TaskChatMetricCard(label: String(localized: "Visible"), value: visibleCount.formatted(), systemImage: "rectangle.grid.2x2", tint: .neutral),
                TaskChatMetricCard(label: String(localized: "Blocked"), value: blockedTasks.count.formatted(), systemImage: "pause.circle.fill", tint: .blocked),
                TaskChatMetricCard(label: String(localized: "Closed history"), value: completedTasks.count.formatted(), systemImage: "checkmark.seal.fill", tint: .done)
            ],
            bars: [
                TaskChatBar(label: TaskStatus.todo.localizedName, value: Double(todoCount), displayValue: todoCount.formatted(), tint: .todo),
                TaskChatBar(label: TaskStatus.inProgress.localizedName, value: Double(inProgressCount), displayValue: inProgressCount.formatted(), tint: .inProgress),
                TaskChatBar(label: TaskStatus.done.localizedName, value: Double(doneVisibleCount), displayValue: doneVisibleCount.formatted(), tint: .done),
                TaskChatBar(label: String(localized: "Archived Done"), value: Double(archivedDoneCount), displayValue: archivedDoneCount.formatted(), tint: .neutral)
            ]
        )
    }

    private static func priorityBreakdownVisualization(tasks: [TaskItem]) -> TaskChatVisualization {
        let visibleTasks = tasks.filter { !$0.isArchived }
        let bars = TaskPriority.allCases.map { priority in
            let count = visibleTasks.filter { $0.priority == priority }.count
            return TaskChatBar(
                label: priority.localizedName,
                value: Double(count),
                displayValue: count.formatted(),
                tint: tint(for: priority)
            )
        }

        return TaskChatVisualization(
            kind: .priorityBreakdown,
            title: String(localized: "Priority Breakdown"),
            subtitle: String(localized: "\(visibleTasks.count.formatted()) visible tasks by priority"),
            metricCards: bars.map {
                TaskChatMetricCard(
                    label: $0.label,
                    value: $0.displayValue,
                    systemImage: "flag.fill",
                    tint: $0.tint
                )
            },
            bars: bars
        )
    }

    private static func activeAgingVisualization(tasks: [TaskItem], now: Date) -> TaskChatVisualization {
        let activeTasks = tasks
            .filter { !$0.isArchived && $0.status == .inProgress }
            .sorted { lhs, rhs in
                let lhsDate = lhs.enteredInProgressAt ?? lhs.lastStatusChange
                let rhsDate = rhs.enteredInProgressAt ?? rhs.lastStatusChange
                return lhsDate < rhsDate
            }
        let oldestTask = activeTasks.first
        let blockedCount = activeTasks.filter(\.isBlocked).count

        return TaskChatVisualization(
            kind: .activeAging,
            title: String(localized: "Active Aging"),
            subtitle: activeTasks.isEmpty
                ? String(localized: "No active tasks are in progress.")
                : String(localized: "\(activeTasks.count.formatted()) active tasks ordered by time in progress"),
            metricCards: [
                TaskChatMetricCard(label: String(localized: "Active"), value: activeTasks.count.formatted(), systemImage: "clock.fill", tint: .inProgress),
                TaskChatMetricCard(label: String(localized: "Blocked"), value: blockedCount.formatted(), systemImage: "pause.circle.fill", tint: .blocked),
                TaskChatMetricCard(
                    label: String(localized: "Oldest"),
                    value: oldestTask.map { durationText(now.timeIntervalSince($0.enteredInProgressAt ?? $0.lastStatusChange)) } ?? String(localized: "None"),
                    systemImage: "hourglass",
                    tint: .neutral
                )
            ],
            bars: activeTasks.prefix(5).map { task in
                let age = now.timeIntervalSince(task.enteredInProgressAt ?? task.lastStatusChange)
                return TaskChatBar(
                    label: normalized(task.title, maxLength: 34),
                    value: age,
                    displayValue: durationText(age),
                    tint: task.isBlocked ? .blocked : .inProgress
                )
            },
            table: TaskChatTable(
                columns: [
                    String(localized: "Task"),
                    String(localized: "Age"),
                    String(localized: "Priority"),
                    String(localized: "State")
                ],
                rows: activeTasks.prefix(6).map { task in
                    let age = now.timeIntervalSince(task.enteredInProgressAt ?? task.lastStatusChange)
                    return TaskChatTableRow(
                        values: [
                            normalized(task.title, maxLength: 44),
                            durationText(age),
                            task.priority.localizedName,
                            task.isBlocked ? String(localized: "Blocked") : String(localized: "Active")
                        ],
                        taskID: task.id
                    )
                }
            )
        )
    }

    private static func completedThisMonthVisualization(tasks: [CompletedTaskFact], monthText: String) -> TaskChatVisualization {
        let averageDuration = tasks.isEmpty
            ? nil
            : tasks.map(\.duration).reduce(0, +) / Double(tasks.count)
        let longestTask = tasks.max { $0.duration < $1.duration }

        return TaskChatVisualization(
            kind: .completedThisMonth,
            title: String(localized: "Completed This Month"),
            subtitle: String(localized: "\(monthText) completed task summary"),
            metricCards: [
                TaskChatMetricCard(label: String(localized: "Closed"), value: tasks.count.formatted(), systemImage: "checkmark.circle.fill", tint: .done),
                TaskChatMetricCard(label: String(localized: "Average close"), value: averageDuration.map(durationText) ?? String(localized: "None"), systemImage: "gauge.with.dots.needle.33percent", tint: .neutral),
                TaskChatMetricCard(label: String(localized: "Slowest"), value: longestTask.map { durationText($0.duration) } ?? String(localized: "None"), systemImage: "hourglass", tint: .high)
            ],
            bars: tasks.sorted { $0.duration > $1.duration }.prefix(5).map { task in
                TaskChatBar(
                    label: normalized(task.title, maxLength: 34),
                    value: task.duration,
                    displayValue: durationText(task.duration),
                    tint: .done
                )
            },
            table: TaskChatTable(
                columns: [
                    String(localized: "Task"),
                    String(localized: "Closed"),
                    String(localized: "Time"),
                    String(localized: "Priority")
                ],
                rows: tasks.prefix(6).map { task in
                    TaskChatTableRow(
                        values: [
                            normalized(task.title, maxLength: 44),
                            dateText(task.closedAt),
                            durationText(task.duration),
                            task.priority.localizedName
                        ],
                        taskID: task.id
                    )
                }
            )
        )
    }

    private static func slowestClosedVisualization(
        tasks: [CompletedTaskFact],
        averageCloseDuration: TimeInterval?,
        longestToClose: CompletedTaskFact?
    ) -> TaskChatVisualization {
        let rankedTasks = tasks.sorted { $0.duration > $1.duration }

        return TaskChatVisualization(
            kind: .slowestClosed,
            title: String(localized: "Slowest To Close"),
            subtitle: rankedTasks.isEmpty
                ? String(localized: "No completed tasks with close dates yet.")
                : String(localized: "Completed tasks ranked by time to close"),
            metricCards: [
                TaskChatMetricCard(label: String(localized: "Completed"), value: rankedTasks.count.formatted(), systemImage: "checkmark.seal.fill", tint: .done),
                TaskChatMetricCard(label: String(localized: "Average"), value: averageCloseDuration.map(durationText) ?? String(localized: "None"), systemImage: "gauge.with.dots.needle.50percent", tint: .neutral),
                TaskChatMetricCard(label: String(localized: "Longest"), value: longestToClose.map { durationText($0.duration) } ?? String(localized: "None"), systemImage: "hourglass", tint: .high)
            ],
            bars: rankedTasks.prefix(5).map { task in
                TaskChatBar(
                    label: normalized(task.title, maxLength: 34),
                    value: task.duration,
                    displayValue: durationText(task.duration),
                    tint: .done
                )
            },
            table: TaskChatTable(
                columns: [
                    String(localized: "Task"),
                    String(localized: "Time"),
                    String(localized: "Closed"),
                    String(localized: "Priority")
                ],
                rows: rankedTasks.prefix(6).map { task in
                    TaskChatTableRow(
                        values: [
                            normalized(task.title, maxLength: 44),
                            durationText(task.duration),
                            dateText(task.closedAt),
                            task.priority.localizedName
                        ],
                        taskID: task.id
                    )
                }
            )
        )
    }

    private static func blockedTasksVisualization(tasks: [TaskItem], now: Date) -> TaskChatVisualization {
        let rankedTasks = tasks.sorted {
            ($0.enteredInProgressAt ?? $0.lastStatusChange) < ($1.enteredInProgressAt ?? $1.lastStatusChange)
        }

        return TaskChatVisualization(
            kind: .blockedTasks,
            title: String(localized: "Blocked Tasks"),
            subtitle: rankedTasks.isEmpty
                ? String(localized: "No active tasks are blocked.")
                : String(localized: "\(rankedTasks.count.formatted()) active tasks currently blocked"),
            metricCards: [
                TaskChatMetricCard(label: String(localized: "Blocked"), value: rankedTasks.count.formatted(), systemImage: "pause.circle.fill", tint: .blocked),
                TaskChatMetricCard(
                    label: String(localized: "Oldest block"),
                    value: rankedTasks.first.map { durationText(now.timeIntervalSince($0.enteredInProgressAt ?? $0.lastStatusChange)) } ?? String(localized: "None"),
                    systemImage: "hourglass",
                    tint: .high
                )
            ],
            bars: rankedTasks.prefix(5).map { task in
                let age = now.timeIntervalSince(task.enteredInProgressAt ?? task.lastStatusChange)
                return TaskChatBar(
                    label: normalized(task.title, maxLength: 34),
                    value: age,
                    displayValue: durationText(age),
                    tint: .blocked
                )
            },
            table: TaskChatTable(
                columns: [
                    String(localized: "Task"),
                    String(localized: "Age"),
                    String(localized: "Priority"),
                    String(localized: "Detail")
                ],
                rows: rankedTasks.prefix(6).map { task in
                    let description = normalized(task.desc, maxLength: 36)
                    let age = now.timeIntervalSince(task.enteredInProgressAt ?? task.lastStatusChange)
                    return TaskChatTableRow(
                        values: [
                            normalized(task.title, maxLength: 44),
                            durationText(age),
                            task.priority.localizedName,
                            description.isEmpty ? String(localized: "No detail") : description
                        ],
                        taskID: task.id
                    )
                }
            )
        )
    }

    private static func throughputTrendVisualization(buckets: [TaskChatTimeBucket]) -> TaskChatVisualization {
        let current = buckets.last
        let previous = buckets.dropLast().last
        let delta = (current?.count ?? 0) - (previous?.count ?? 0)

        return TaskChatVisualization(
            kind: .throughputTrend,
            title: String(localized: "Throughput Trend"),
            subtitle: String(localized: "Closed tasks by week"),
            metricCards: [
                TaskChatMetricCard(label: String(localized: "This week"), value: (current?.count ?? 0).formatted(), systemImage: "calendar.badge.checkmark", tint: .done),
                TaskChatMetricCard(label: String(localized: "Last week"), value: (previous?.count ?? 0).formatted(), systemImage: "arrow.uturn.backward.circle.fill", tint: .neutral),
                TaskChatMetricCard(label: String(localized: "Change"), value: signedCount(delta), systemImage: delta >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill", tint: delta >= 0 ? .done : .high)
            ],
            bars: buckets.map { bucket in
                TaskChatBar(
                    label: bucket.label,
                    value: Double(bucket.count),
                    displayValue: bucket.count.formatted(),
                    tint: .done
                )
            },
            table: TaskChatTable(
                columns: [
                    String(localized: "Week"),
                    String(localized: "Closed"),
                    String(localized: "Average close")
                ],
                rows: buckets.map { bucket in
                    TaskChatTableRow(
                        values: [
                            bucket.label,
                            bucket.count.formatted(),
                            bucket.averageDuration.map(durationText) ?? String(localized: "None")
                        ]
                    )
                }
            )
        )
    }

    private static func closeTimeTrendVisualization(buckets: [TaskChatTimeBucket]) -> TaskChatVisualization {
        let current = buckets.last
        let previous = buckets.dropLast().last
        let currentAverage = current?.averageDuration
        let previousAverage = previous?.averageDuration

        return TaskChatVisualization(
            kind: .closeTimeTrend,
            title: String(localized: "Close Time Trend"),
            subtitle: String(localized: "Average close time by week"),
            metricCards: [
                TaskChatMetricCard(label: String(localized: "This week"), value: currentAverage.map(durationText) ?? String(localized: "None"), systemImage: "gauge.with.dots.needle.33percent", tint: .neutral),
                TaskChatMetricCard(label: String(localized: "Last week"), value: previousAverage.map(durationText) ?? String(localized: "None"), systemImage: "arrow.uturn.backward.circle.fill", tint: .neutral),
                TaskChatMetricCard(label: String(localized: "Change"), value: signedDuration(currentAverage, previousAverage), systemImage: "arrow.left.arrow.right.circle.fill", tint: .neutral)
            ],
            bars: buckets.map { bucket in
                let average = bucket.averageDuration ?? 0
                return TaskChatBar(
                    label: bucket.label,
                    value: average,
                    displayValue: bucket.averageDuration.map(durationText) ?? String(localized: "None"),
                    tint: average > 0 ? .neutral : .low
                )
            },
            table: TaskChatTable(
                columns: [
                    String(localized: "Week"),
                    String(localized: "Average close"),
                    String(localized: "Closed")
                ],
                rows: buckets.map { bucket in
                    TaskChatTableRow(
                        values: [
                            bucket.label,
                            bucket.averageDuration.map(durationText) ?? String(localized: "None"),
                            bucket.count.formatted()
                        ]
                    )
                }
            )
        )
    }

    private static func periodComparisonVisualization(
        kind: TaskChatVisualizationKind,
        title: String,
        currentLabel: String,
        previousLabel: String,
        currentTasks: [CompletedTaskFact],
        previousTasks: [CompletedTaskFact]
    ) -> TaskChatVisualization {
        let delta = currentTasks.count - previousTasks.count
        let currentAverage = averageDuration(currentTasks)
        let previousAverage = averageDuration(previousTasks)

        return TaskChatVisualization(
            kind: kind,
            title: title,
            subtitle: String(localized: "Closed tasks compared by period"),
            metricCards: [
                TaskChatMetricCard(label: currentLabel, value: currentTasks.count.formatted(), systemImage: "calendar.badge.checkmark", tint: .done),
                TaskChatMetricCard(label: previousLabel, value: previousTasks.count.formatted(), systemImage: "arrow.uturn.backward.circle.fill", tint: .neutral),
                TaskChatMetricCard(label: String(localized: "Change"), value: signedCount(delta), systemImage: delta >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill", tint: delta >= 0 ? .done : .high)
            ],
            bars: [
                TaskChatBar(label: currentLabel, value: Double(currentTasks.count), displayValue: currentTasks.count.formatted(), tint: .done),
                TaskChatBar(label: previousLabel, value: Double(previousTasks.count), displayValue: previousTasks.count.formatted(), tint: .neutral)
            ],
            table: TaskChatTable(
                columns: [
                    String(localized: "Period"),
                    String(localized: "Closed"),
                    String(localized: "Average close")
                ],
                rows: [
                    TaskChatTableRow(values: [currentLabel, currentTasks.count.formatted(), currentAverage.map(durationText) ?? String(localized: "None")]),
                    TaskChatTableRow(values: [previousLabel, previousTasks.count.formatted(), previousAverage.map(durationText) ?? String(localized: "None")])
                ]
            )
        )
    }

    private static func priorityCloseTimeVisualization(tasks: [CompletedTaskFact]) -> TaskChatVisualization {
        let priorityRows = TaskPriority.allCases.map { priority in
            let priorityTasks = tasks.filter { $0.priority == priority }
            return (priority: priority, tasks: priorityTasks, average: averageDuration(priorityTasks))
        }

        return TaskChatVisualization(
            kind: .priorityCloseTime,
            title: String(localized: "Priority Close Time"),
            subtitle: String(localized: "Average close time by priority"),
            metricCards: priorityRows.map { row in
                TaskChatMetricCard(
                    label: row.priority.localizedName,
                    value: row.average.map(durationText) ?? String(localized: "None"),
                    systemImage: "flag.fill",
                    tint: tint(for: row.priority)
                )
            },
            bars: priorityRows.map { row in
                TaskChatBar(
                    label: row.priority.localizedName,
                    value: row.average ?? 0,
                    displayValue: row.average.map(durationText) ?? String(localized: "None"),
                    tint: tint(for: row.priority)
                )
            },
            table: TaskChatTable(
                columns: [
                    String(localized: "Priority"),
                    String(localized: "Average close"),
                    String(localized: "Closed")
                ],
                rows: priorityRows.map { row in
                    TaskChatTableRow(
                        values: [
                            row.priority.localizedName,
                            row.average.map(durationText) ?? String(localized: "None"),
                            row.tasks.count.formatted()
                        ]
                    )
                }
            )
        )
    }

    private static func tint(for priority: TaskPriority) -> TaskChatVisualizationTint {
        switch priority {
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }

    private static func currentTaskLine(for task: TaskItem, now: Date) -> String {
        let activeSince = task.status == .inProgress ? (task.enteredInProgressAt ?? task.lastStatusChange) : nil
        let activeAge = activeSince.map { durationText(now.timeIntervalSince($0)) } ?? String(localized: "not active")
        let description = normalized(task.desc, maxLength: 140)
        let completionCriteria = normalized(task.completionCriteria, maxLength: 120)

        return "- id: \(task.id.uuidString) | title: \(normalized(task.title, maxLength: 90)) | status: \(task.status.rawValue) | priority: \(task.priority.rawValue) | blocked: \(task.isBlocked ? "yes" : "no") | created: \(dateText(task.createdAt)) | active age: \(activeAge) | description: \(description.isEmpty ? "none" : description) | definition of done: \(completionCriteria.isEmpty ? "none" : completionCriteria)"
    }

    private static func weeklyBuckets(completedTasks: [CompletedTaskFact], now: Date, calendar: Calendar, count: Int = 6) -> [TaskChatTimeBucket] {
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return (0..<count).reversed().map { offset in
            let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeekStart) ?? currentWeekStart
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
            let tasks = completedTasks.filter { $0.closedAt >= start && $0.closedAt < end && $0.closedAt <= now }
            return TaskChatTimeBucket(
                label: dateText(start),
                start: start,
                end: end,
                tasks: tasks
            )
        }
    }

    private static func averageDuration(_ tasks: [CompletedTaskFact]) -> TimeInterval? {
        guard !tasks.isEmpty else { return nil }
        return tasks.map(\.duration).reduce(0, +) / Double(tasks.count)
    }

    private static func weeklyThroughputPromptLine(_ buckets: [TaskChatTimeBucket]) -> String {
        guard !buckets.isEmpty else { return "No completed tasks with close dates." }
        return buckets
            .map { "\($0.label)=\($0.count) closed" }
            .joined(separator: "; ")
    }

    private static func weeklyCloseTimePromptLine(_ buckets: [TaskChatTimeBucket]) -> String {
        guard !buckets.isEmpty else { return "No completed tasks with close dates." }
        return buckets
            .map { bucket in
                let average = bucket.averageDuration.map(durationText) ?? "none"
                return "\(bucket.label)=\(average)"
            }
            .joined(separator: "; ")
    }

    private static func priorityCloseTimePromptLine(_ tasks: [CompletedTaskFact]) -> String {
        TaskPriority.allCases
            .map { priority in
                let matchingTasks = tasks.filter { $0.priority == priority }
                let average = averageDuration(matchingTasks).map(durationText) ?? "none"
                return "\(priority.rawValue)=\(average) across \(matchingTasks.count) closed"
            }
            .joined(separator: "; ")
    }

    private static func signedCount(_ value: Int) -> String {
        value > 0 ? "+\(value)" : value.formatted()
    }

    private static func signedDuration(_ current: TimeInterval?, _ previous: TimeInterval?) -> String {
        guard let current, let previous else { return String(localized: "None") }
        let delta = current - previous
        let prefix = delta > 0 ? "+" : delta < 0 ? "-" : ""
        return "\(prefix)\(durationText(abs(delta)))"
    }

    fileprivate static func normalized(_ value: String, maxLength: Int) -> String {
        let flattened = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard flattened.count > maxLength else { return flattened }
        return "\(flattened.prefix(max(maxLength - 3, 0)))..."
    }

    static func dateText(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    fileprivate static func dateTimeText(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    fileprivate static func monthText(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        let seconds = max(seconds, 0)
        let days = Int(seconds / 86_400)
        if days == 1 { return String(localized: "1 day") }
        if days > 1 { return String(localized: "\(days) days") }

        let hours = Int(seconds / 3_600)
        if hours == 1 { return String(localized: "1 hour") }
        if hours > 1 { return String(localized: "\(hours) hours") }

        let minutes = max(Int(seconds / 60), 1)
        if minutes == 1 { return String(localized: "1 minute") }
        return String(localized: "\(minutes) minutes")
    }
}

enum TaskChatService {
    private static let model = SystemLanguageModel.default

    static var availability: QuickCaptureAvailability {
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailable(String(localized: "Apple Intelligence is not supported on this device."))
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable(String(localized: "Turn on Apple Intelligence in Settings to ask questions about your tasks."))
        case .unavailable(.modelNotReady):
            return .unavailable(String(localized: "Apple Intelligence is getting ready. Try again in a moment."))
        case .unavailable:
            return .unavailable(String(localized: "Task chat is unavailable right now."))
        }
    }

    static func respond(to request: TaskChatRequest) async throws -> TaskChatResponse {
        if let response = deterministicSmallTalkResponse(for: request.question) {
            return response
        }

        let session = LanguageModelSession(
            instructions: """
            You are the private on-device task analyst in a Personal Kanban app.

            You answer questions using only the supplied local board facts. The deterministic metrics are already computed by the app and must be treated as exact. If the user asks for a metric that appears in the deterministic metrics, use that value instead of recalculating from the task list.

            If the current user message is only a greeting, thanks, or small talk, answer naturally without using board metrics, task lists, references, proposed actions, tables, or charts.

            Board facts include task UUIDs so the app can render tappable references. Use those UUIDs only in referencedTaskIDs when the answer directly mentions or depends on specific tasks. Never expose UUIDs to the user.

            Follow the response language specified in the prompt. Keep task titles exactly as written.

            Leave proposedActions empty unless the user explicitly asks you to perform one specific task action. Do not propose actions for analysis, metrics, recommendations, tables, charts, lists, rankings, or prioritization questions. Do not propose or create next actions from chat. When the user does ask for an action, the app will still require confirmation before applying it. Do not propose actions for task states that do not make sense: only archive Done tasks; only mark In Progress tasks blocked or active.

            The chat is read-only until the user confirms an action. Do not claim that you changed tasks. Do not suggest external integrations. Do not mention Apple Intelligence, Foundation Models, prompts, or implementation details.
            """
        )

        let response = try await session.respond(
            to: request.prompt,
            generating: TaskChatAnswerDraft.self
        )
        let content = response.content
        let proposedActions = focusedProposedActions(content.proposedActions, for: request.question)
        let visualizations = focusedVisualizations(for: request.question, in: request.snapshot)

        return TaskChatResponse(
            answer: content.answer.trimmingCharacters(in: .whitespacesAndNewlines),
            metricSummary: content.metricSummary.trimmingCharacters(in: .whitespacesAndNewlines),
            referencedTaskIDs: parseUUIDs(content.referencedTaskIDs),
            proposedActions: proposedActions,
            visualizations: visualizations,
            evidence: request.snapshot.evidence(
                for: request.question,
                metricSummary: content.metricSummary.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
    }

    private static func deterministicSmallTalkResponse(for question: String) -> TaskChatResponse? {
        let phrase = smallTalkPhrase(for: question)
        let greetingPhrases: Set<String> = [
            "hi",
            "hi there",
            "hello",
            "hello there",
            "hey",
            "hey there",
            "good morning",
            "good afternoon",
            "good evening"
        ]
        let thanksPhrases: Set<String> = [
            "thanks",
            "thank you",
            "thx",
            "thanks a lot",
            "thank you very much"
        ]

        if greetingPhrases.contains(phrase) {
            return simpleResponse(String(localized: "Hi."))
        }
        if thanksPhrases.contains(phrase) {
            return simpleResponse(String(localized: "You're welcome."))
        }
        return nil
    }

    private static func smallTalkPhrase(for question: String) -> String {
        question
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func simpleResponse(_ answer: String) -> TaskChatResponse {
        TaskChatResponse(
            answer: answer,
            metricSummary: "",
            referencedTaskIDs: [],
            proposedActions: [],
            visualizations: [],
            evidence: nil
        )
    }

    private static func parseUUIDs(_ rawValue: String) -> [UUID] {
        rawValue
            .split(whereSeparator: { $0 == "," || $0 == "\n" || $0 == ";" })
            .compactMap { UUID(uuidString: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .uniquePreservingOrder()
    }

    private static func parseProposedActions(_ rawValue: String) -> [TaskChatProposedAction] {
        rawValue
            .components(separatedBy: .newlines)
            .compactMap(parseProposedActionLine)
            .limited(to: 2)
    }

    private static func parseProposedActionLine(_ line: String) -> TaskChatProposedAction? {
        let fields = line
            .split(separator: "|", maxSplits: 4, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard fields.count >= 4 else { return nil }
        guard let kind = TaskChatActionKind(rawValue: fields[0]) else { return nil }
        guard let taskID = UUID(uuidString: fields[1]) else { return nil }

        let confirmationLabel = fields[3].isEmpty ? kind.fallbackConfirmationLabel : fields[3]
        let payload = fields.count >= 5 ? fields[4] : ""

        return TaskChatProposedAction(
            kind: kind,
            taskID: taskID,
            taskTitle: fields[2],
            confirmationLabel: confirmationLabel,
            payload: payload
        )
    }

    private static func focusedProposedActions(_ rawValue: String, for question: String) -> [TaskChatProposedAction] {
        let allowedKinds = allowedActionKinds(for: question)
        guard !allowedKinds.isEmpty else { return [] }

        return parseProposedActions(rawValue)
            .filter { allowedKinds.contains($0.kind) }
            .limited(to: 2)
    }

    private static func allowedActionKinds(for question: String) -> Set<TaskChatActionKind> {
        let text = question.lowercased()
        guard !containsAny(text, ["what should", "which task should", "recommend", "suggest", "why", "how many", "add next action", "add a next action", "append next action", "add next step", "add a next step"]) else {
            return []
        }

        var kinds: Set<TaskChatActionKind> = []

        if containsAny(text, ["open task", "open the task", "open details", "task details", "review task"]) {
            kinds.insert(.openTask)
        }
        if (text.contains("mark") || text.contains("set")) && text.contains("blocked") {
            kinds.insert(.markBlocked)
        }
        if containsAny(text, ["unblock", "remove block"]) || ((text.contains("mark") || text.contains("set")) && text.contains("active")) {
            kinds.insert(.markActive)
        }
        if containsAny(text, ["move", "send", "put"]) && containsAny(text, ["to do", "todo"]) {
            kinds.insert(.moveToTodo)
        }
        if containsAny(text, ["move", "send", "put"]) && containsAny(text, ["in progress", "wip"]) {
            kinds.insert(.moveToInProgress)
        }
        if (text.contains("mark") || text.contains("set") || text.contains("move")) && text.contains("done") {
            kinds.insert(.markDone)
        }
        if text.contains("archive") {
            kinds.insert(.archiveDoneTask)
        }

        return kinds
    }

    private static func containsAny(_ text: String, _ values: [String]) -> Bool {
        values.contains { text.contains($0) }
    }

    private static func focusedVisualizations(for question: String, in snapshot: TaskChatBoardSnapshot) -> [TaskChatVisualization] {
        inferredVisualizationKinds(for: question)
            .compactMap { snapshot.visualizations(for: [$0]).first }
            .map { focusedVisualization($0, for: question) }
    }

    private static func inferredVisualizationKinds(for question: String) -> [TaskChatVisualizationKind] {
        let text = question.lowercased()
        let asksForVisual = [
            "table",
            "list",
            "chart",
            "graph",
            "graphic",
            "visual",
            "breakdown",
            "trend",
            "rank",
            "ranking",
            "compare",
            "show",
            "show me",
            "display",
            "plot"
        ].contains { text.contains($0) }
        guard asksForVisual else { return [] }

        if (text.contains("week") || text.contains("last week")) && containsAny(text, ["compare", "versus", "vs"]) {
            return [.weekComparison]
        }
        if (text.contains("month") || text.contains("last month")) && containsAny(text, ["compare", "versus", "vs"]) {
            return [.monthComparison]
        }
        if containsAny(text, ["close time", "cycle time", "average close", "time to close"]) && text.contains("priority") {
            return [.priorityCloseTime]
        }
        if containsAny(text, ["close time", "cycle time", "average close", "time to close"]) && containsAny(text, ["trend", "week", "weekly", "getting better", "getting worse"]) {
            return [.closeTimeTrend]
        }
        if text.contains("throughput") || (containsAny(text, ["week", "weekly", "trend"]) && containsAny(text, ["closed", "completed", "done"])) {
            return [.throughputTrend]
        }
        if text.contains("blocked") {
            return [.blockedTasks]
        }
        if text.contains("priority") {
            return [.priorityBreakdown]
        }
        if text.contains("slowest") || text.contains("longest") || text.contains("longer") || text.contains("took") {
            return [.slowestClosed]
        }
        if text.contains("month") || text.contains("closed") || text.contains("completed") {
            return [.completedThisMonth]
        }
        if text.contains("active") || text.contains("aging") || text.contains("oldest") || text.contains("stale") || text.contains("progress") {
            return [.activeAging]
        }
        if text.contains("status") || text.contains("board") || text.contains("wip") || text.contains("work in progress") {
            return [.statusBreakdown]
        }

        return []
    }

    private static func focusedVisualization(_ visualization: TaskChatVisualization, for question: String) -> TaskChatVisualization {
        let text = question.lowercased()
        let wantsTable = [
            "table",
            "list",
            "rank",
            "ranking",
            "rows"
        ].contains { text.contains($0) }
        let wantsChart = [
            "chart",
            "graph",
            "graphic",
            "bar"
        ].contains { text.contains($0) }

        if wantsTable, visualization.table != nil {
            return TaskChatVisualization(
                kind: visualization.kind,
                title: visualization.title,
                subtitle: visualization.subtitle,
                table: visualization.table
            )
        }

        if wantsChart {
            return TaskChatVisualization(
                kind: visualization.kind,
                title: visualization.title,
                subtitle: visualization.subtitle,
                bars: visualization.bars
            )
        }

        return TaskChatVisualization(
            kind: visualization.kind,
            title: visualization.title,
            subtitle: visualization.subtitle,
            metricCards: visualization.metricCards,
            bars: visualization.table == nil ? visualization.bars : [],
            table: visualization.table
        )
    }
}

private struct TaskChatTimeBucket {
    let label: String
    let start: Date
    let end: Date
    let tasks: [CompletedTaskFact]

    var count: Int {
        tasks.count
    }

    var averageDuration: TimeInterval? {
        guard !tasks.isEmpty else { return nil }
        return tasks.map(\.duration).reduce(0, +) / Double(tasks.count)
    }
}

private struct CompletedTaskFact {
    let id: UUID
    let title: String
    let createdAt: Date
    let closedAt: Date
    let duration: TimeInterval
    let priority: TaskPriority
    let isArchived: Bool
    let description: String
    let completionCriteria: String

    init?(task: TaskItem) {
        guard task.status == .done else { return nil }
        let closedAt = task.finalizedAt ?? task.updatedAt
        guard closedAt >= task.createdAt else { return nil }

        self.id = task.id
        self.title = task.title
        self.createdAt = task.createdAt
        self.closedAt = closedAt
        self.duration = closedAt.timeIntervalSince(task.createdAt)
        self.priority = task.priority
        self.isArchived = task.isArchived
        self.description = task.desc
        self.completionCriteria = task.completionCriteria
    }

    var metricLine: String {
        "\(TaskChatBoardSnapshot.durationText(duration)) - \(TaskChatBoardSnapshot.normalized(title, maxLength: 90)) (created \(TaskChatBoardSnapshot.dateText(createdAt)), closed \(TaskChatBoardSnapshot.dateText(closedAt)))"
    }

    var promptLine: String {
        let description = TaskChatBoardSnapshot.normalized(description, maxLength: 140)
        let completionCriteria = TaskChatBoardSnapshot.normalized(completionCriteria, maxLength: 120)
        return "- id: \(id.uuidString) | title: \(TaskChatBoardSnapshot.normalized(title, maxLength: 90)) | status: Done | priority: \(priority.rawValue) | archived: \(isArchived ? "yes" : "no") | created: \(TaskChatBoardSnapshot.dateText(createdAt)) | closed: \(TaskChatBoardSnapshot.dateText(closedAt)) | time to close: \(TaskChatBoardSnapshot.durationText(duration)) | description: \(description.isEmpty ? "none" : description) | definition of done: \(completionCriteria.isEmpty ? "none" : completionCriteria)"
    }
}

private extension Array where Element: Hashable {
    func uniquePreservingOrder() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

private extension String {
    var evidenceSearchText: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private extension Array {
    func limited(to count: Int) -> [Element] {
        Array(self[0..<Swift.min(count, self.count)])
    }
}
