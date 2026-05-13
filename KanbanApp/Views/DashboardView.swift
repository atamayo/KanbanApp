import SwiftUI
struct DashboardView: View {
    let allTasks: [TaskItem]
    var onSelectStatus: ((TaskStatus) -> Void)? = nil
    
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0
    @State private var selectedCoachTask: TaskItem?

    // MARK: - Data

    private var currentTasks: [TaskItem] {
        allTasks.filter { !$0.isArchived }
    }

    private var totalCount: Int { currentTasks.count }
    private var doneCount: Int { currentTasks.filter { $0.status == .done }.count }
    private var inProgressCount: Int { currentTasks.filter { $0.status == .inProgress }.count }
    private var todoCount: Int { currentTasks.filter { $0.status == .todo }.count }

    private func count(priority: TaskPriority) -> Int {
        currentTasks.filter { $0.priority == priority }.count
    }

    private var maxPriorityCount: Int {
        max(count(priority: .high), count(priority: .medium), count(priority: .low))
    }

    private var oldestInProgressTask: TaskItem? {
        currentTasks
            .filter { $0.status == .inProgress && !$0.isBlocked }
            .sorted { $0.lastStatusChange < $1.lastStatusChange }
            .first
    }

    private var blockedInProgressTask: TaskItem? {
        currentTasks
            .filter { $0.status == .inProgress && $0.isBlocked }
            .sorted { $0.updatedAt < $1.updatedAt }
            .first
    }

    private var nextPullTask: TaskItem? {
        currentTasks
            .filter { $0.status == .todo }
            .sorted { lhs, rhs in
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                return lhs.createdAt < rhs.createdAt
            }
            .first
    }

    private var agingInProgressTasks: [TaskItem] {
        currentTasks
            .filter {
                $0.status == .inProgress &&
                !$0.isBlocked &&
                Date().timeIntervalSince($0.lastStatusChange) >= (3 * 24 * 60 * 60) &&
                Date().timeIntervalSince($0.lastStatusChange) < (5 * 24 * 60 * 60)
            }
            .sorted { $0.lastStatusChange < $1.lastStatusChange }
    }

    private var stalledInProgressTasks: [TaskItem] {
        currentTasks
            .filter {
                $0.status == .inProgress &&
                !$0.isBlocked &&
                Date().timeIntervalSince($0.lastStatusChange) >= (5 * 24 * 60 * 60)
            }
            .sorted { $0.lastStatusChange < $1.lastStatusChange }
    }

    private var doneThisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allTasks.filter {
            $0.status == .done && ($0.finalizedAt ?? $0.updatedAt) >= weekAgo
        }.count
    }

    private var tasksWithCompletionCriteria: Int {
        currentTasks.filter { !$0.completionCriteria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var doneTasksWithCycleTime: [TaskItem] {
        allTasks.filter { $0.status == .done && $0.enteredInProgressAt != nil && ($0.finalizedAt ?? $0.updatedAt) >= ($0.enteredInProgressAt ?? .distantPast) }
    }

    private var averageDaysToDone: Double? {
        let durations = doneTasksWithCycleTime.map { ($0.finalizedAt ?? $0.updatedAt).timeIntervalSince($0.enteredInProgressAt ?? ($0.finalizedAt ?? $0.updatedAt)) }
        guard !durations.isEmpty else { return nil }
        let averageSeconds = durations.reduce(0, +) / Double(durations.count)
        return averageSeconds / (24 * 60 * 60)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if allTasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppStyle.Spacing.compactSectionSpacing) {
                    ProgresView(doneCount: doneCount, totalCount: totalCount)
                    StatusView(
                        todoCount: todoCount,
                        inProgressCount: inProgressCount,
                        doneCount: doneCount,
                        totalCount: totalCount,
                        maxActiveTasks: maxActiveTasks,
                        isFocusGuardEnabled: isFocusGuardEnabled,
                        onSelectStatus: onSelectStatus
                    )
                    prioritySection
                    
                    WIPView(
                        allTasks: currentTasks,
                        maxActiveTasks: maxActiveTasks,
                        isFocusGuardEnabled: isFocusGuardEnabled,
                        onReviewActiveTasks: { onSelectStatus?(.inProgress) },
                        onOpenTask: { task in
                            selectedCoachTask = task
                        }
                    )

                    flowReviewSection
                    trendSection
                    
                    momentumSection
                }
                .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
                .padding(.vertical, AppStyle.Spacing.outerVertical)
            }
        }
        .background(AppStyle.Colors.background)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .contentMargins(.top, AppStyle.Spacing.small, for: .scrollContent)
        .contentMargins(.bottom, AppStyle.Spacing.extraLarge, for: .scrollContent)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedCoachTask) { task in
            TaskDetailView(task: task)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Image(systemName: "square.3.layers.3d")
                .font(AppStyle.Typography.emptyIcon)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Text("No tasks yet")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)

            Text("Add a task to populate your dashboard")
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(AppStyle.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppStyle.Spacing.emptyStateVerticalPadding)
    }

    // MARK: - Priority

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Priority")

            HStack(spacing: AppStyle.Spacing.priorityHStackGap) {
                priorityCard(priority: "High", count: count(priority: .high), tint: AppStyle.Colors.Priority.high)
                priorityCard(priority: "Medium", count: count(priority: .medium), tint: AppStyle.Colors.Priority.medium)
                priorityCard(priority: "Low", count: count(priority: .low), tint: AppStyle.Colors.Priority.low)
            }
        }
    }

    private func priorityCard(priority: String, count: Int, tint: Color) -> some View {
        let isEmpty = count == 0
        let dominanceRatio = maxPriorityCount > 0 ? CGFloat(count) / CGFloat(maxPriorityCount) : 0
        let fillOpacity = isEmpty ? AppStyle.Opacity.accentWashVeryFaint : AppStyle.Opacity.accentWashEmphasized

        return VStack(spacing: AppStyle.Spacing.none) {
            VStack(spacing: AppStyle.Spacing.priorityCardVStackGap) {
                Text(count.formatted())
                    .font(AppStyle.Typography.priorityNumber)
                    .foregroundStyle(isEmpty ? AppStyle.Colors.tertiaryText : AppStyle.Colors.primaryText)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: AppStyle.Spacing.sectionHStackGap) {
                    Circle()
                        .fill(isEmpty ? AppStyle.Colors.secondaryText.opacity(AppStyle.Opacity.iconInactive) : tint)
                        .frame(width: AppStyle.Shapes.priorityDotSize, height: AppStyle.Shapes.priorityDotSize)
                    Text(priority)
                        .font(AppStyle.Typography.priorityLabelBold)
                        .foregroundStyle(isEmpty ? AppStyle.Colors.tertiaryText : AppStyle.Colors.primaryText)
                }
            }
            .padding(.vertical, AppStyle.Spacing.priorityVerticalPadding)
            .padding(.horizontal, AppStyle.Spacing.statusRowVerticalCompact)
        }
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { geo in
                VStack(spacing: AppStyle.Spacing.none) {
                    let fillHeight = dominanceRatio > 0
                        ? max(
                            AppStyle.Shapes.accentBarHeight,
                            geo.size.height * (AppStyle.Shapes.priorityFillBaseline + (AppStyle.Shapes.priorityFillRange * dominanceRatio))
                        )
                        : AppStyle.Shapes.accentBarHeight

                    tint
                        .opacity(isEmpty ? AppStyle.Opacity.accentFillMuted : fillOpacity)
                        .frame(height: fillHeight)

                    Spacer(minLength: AppStyle.Spacing.none)
                }
            }
        }
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        .opacity(isEmpty ? AppStyle.Opacity.inactiveCard : AppStyle.Opacity.opaque)
    }

    // MARK: - Footer

    private var flowReviewSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Flow Review")

            VStack(spacing: AppStyle.Spacing.statusRowGap) {
                flowReviewCard(
                    title: "Blocked Work",
                    count: blockedInProgressTask == nil ? 0 : currentTasks.filter { $0.status == .inProgress && $0.isBlocked }.count,
                    tint: AppStyle.Colors.blocked,
                    icon: "pause.circle.fill",
                    description: blockedInProgressTask == nil ? "No active blockers right now." : "Blocked tasks need attention before more work is pulled."
                )

                flowReviewCard(
                    title: "Aging Tasks",
                    count: agingInProgressTasks.count,
                    tint: AppStyle.Colors.Priority.medium,
                    icon: "clock.badge.exclamationmark",
                    description: agingInProgressTasks.isEmpty ? "Nothing is drifting yet." : "These tasks are staying active long enough to risk drag."
                )

                flowReviewCard(
                    title: "Stalled Tasks",
                    count: stalledInProgressTasks.count,
                    tint: AppStyle.Colors.Priority.high,
                    icon: "exclamationmark.circle.fill",
                    description: stalledInProgressTasks.isEmpty ? "No stalled work right now." : "These tasks have sat too long in progress and may need a decision."
                )
            }
        }
    }

    private var momentumSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Done Momentum")

            VStack(alignment: .leading, spacing: AppStyle.Spacing.comfortable) {
                HStack(spacing: AppStyle.Spacing.statusRowGap) {
                    momentumStatCard(
                        label: "Done This Week",
                        value: "\(doneThisWeekCount)",
                        tint: AppStyle.Colors.Status.done
                    )

                    momentumStatCard(
                        label: "Clear Finish Checks",
                        value: "\(tasksWithCompletionCriteria)",
                        tint: AppStyle.Colors.Status.todo
                    )
                }

                VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                    Text(momentumHeadline)
                        .font(AppStyle.Typography.metricMedium)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Text(momentumMessage)
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppStyle.Spacing.large)
            .accentCardStyle(tint: AppStyle.Colors.Status.done)
        }
        .padding(.bottom, AppStyle.Spacing.emptyBottomSpacer)
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Flow Trends")

            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                trendCard(
                    label: "Avg Days To Done",
                    value: averageDaysToDone.map { String(format: "%.1f", $0) } ?? "-",
                    tint: AppStyle.Colors.Status.done,
                    note: averageDaysToDone == nil ? "Need completed in-progress tasks" : "From In Progress to Done"
                )

                trendCard(
                    label: "Done This Week",
                    value: "\(doneThisWeekCount)",
                    tint: AppStyle.Colors.Status.todo,
                    note: "Recent finish rate"
                )
            }

            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                trendCard(
                    label: "WIP Limit Hits",
                    value: "\(wipLimitHitCount)",
                    tint: AppStyle.Colors.warning,
                    note: "Times flow pushed back"
                )

                trendCard(
                    label: "Active Age",
                    value: oldestInProgressTask.map { activeAgeText(for: $0) } ?? "-",
                    tint: AppStyle.Colors.Status.inProgress,
                    note: oldestInProgressTask == nil ? "No active task running" : "Oldest active task"
                )
            }
        }
    }

    // MARK: - Shared

    private var momentumHeadline: String {
        if doneThisWeekCount >= 5 {
            return "Strong finishing rhythm."
        }
        if doneThisWeekCount > 0 {
            return "Momentum is visible."
        }
        return "The next finished task changes the board."
    }

    private var momentumMessage: String {
        if doneThisWeekCount >= 5 {
            return "You are turning work into done consistently. Protect that rhythm by keeping WIP tight."
        }
        if doneThisWeekCount > 0 {
            return "Every completed task frees attention and opens space for the next pull."
        }
        return "Close one task and you free a focus slot, strengthen the Done column, and make progress feel real again."
    }

    private func flowReviewCard(title: String, count: Int, tint: Color, icon: String, description: String) -> some View {
        Button {
            onSelectStatus?(.inProgress)
        } label: {
            HStack(alignment: .top, spacing: AppStyle.Spacing.regular) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                        .fill(tint.opacity(AppStyle.Opacity.accentWashStrong))
                        .frame(width: AppStyle.Shapes.iconBadgeSmall, height: AppStyle.Shapes.iconBadgeSmall)

                    Image(systemName: icon)
                        .font(AppStyle.Typography.iconMedium)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                    HStack {
                        Text(title)
                            .font(AppStyle.Typography.statusLabelHighlighted)
                            .foregroundStyle(AppStyle.Colors.primaryText)

                        Spacer()

                        Text("\(count)")
                            .font(AppStyle.Typography.metricMedium)
                            .foregroundStyle(tint)
                    }

                    Text(description)
                        .font(AppStyle.Typography.cardDate)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppStyle.Spacing.cardContentPadding)
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
        .buttonStyle(.plain)
    }

    private func momentumStatCard(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            Text(label)
                .font(AppStyle.Typography.statLabel)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Text(value)
                .font(AppStyle.Typography.metricMedium)
                .foregroundStyle(tint)
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(AppStyle.Opacity.accentWashSubtle), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
    }

    private func trendCard(label: String, value: String, tint: Color, note: String) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            Text(label)
                .font(AppStyle.Typography.statLabel)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Text(value)
                .font(AppStyle.Typography.metricMedium)
                .foregroundStyle(tint)

            Text(note)
                .font(AppStyle.Typography.cardDate)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }

    private func activeAgeText(for task: TaskItem) -> String {
        let days = Int(Date().timeIntervalSince(task.lastStatusChange) / (24 * 60 * 60))
        if days > 0 {
            return "\(days)d"
        }
        let hours = Int(Date().timeIntervalSince(task.lastStatusChange) / (60 * 60))
        if hours > 0 {
            return "\(hours)h"
        }
        let minutes = Int(Date().timeIntervalSince(task.lastStatusChange) / 60)
        return "\(max(minutes, 1))m"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .sectionHeaderStyle()
    }
}
