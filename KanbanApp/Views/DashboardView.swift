import SwiftUI
struct DashboardView: View {
    let allTasks: [TaskItem]
    var onAddTask: (() -> Void)? = nil
    var onSelectStatus: ((TaskStatus) -> Void)? = nil
    
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0

    // MARK: - Data

    private var totalCount: Int { allTasks.count }
    private var doneCount: Int { allTasks.filter { $0.status == .done }.count }
    private var inProgressCount: Int { allTasks.filter { $0.status == .inProgress }.count }
    private var todoCount: Int { allTasks.filter { $0.status == .todo }.count }

    private var donePercent: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }

    private func count(priority: TaskPriority) -> Int {
        allTasks.filter { $0.priority == priority }.count
    }

    private var maxPriorityCount: Int {
        max(count(priority: .high), count(priority: .medium), count(priority: .low))
    }

    private var oldestInProgressTask: TaskItem? {
        allTasks
            .filter { $0.status == .inProgress && !$0.isBlocked }
            .sorted { $0.lastStatusChange < $1.lastStatusChange }
            .first
    }

    private var blockedInProgressTask: TaskItem? {
        allTasks
            .filter { $0.status == .inProgress && $0.isBlocked }
            .sorted { $0.updatedAt < $1.updatedAt }
            .first
    }

    private var nextPullTask: TaskItem? {
        allTasks
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
        allTasks
            .filter {
                $0.status == .inProgress &&
                !$0.isBlocked &&
                Date().timeIntervalSince($0.lastStatusChange) >= (3 * 24 * 60 * 60) &&
                Date().timeIntervalSince($0.lastStatusChange) < (5 * 24 * 60 * 60)
            }
            .sorted { $0.lastStatusChange < $1.lastStatusChange }
    }

    private var stalledInProgressTasks: [TaskItem] {
        allTasks
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
        allTasks.filter { !$0.completionCriteria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
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
                    headerSection
                    statusSection
                    prioritySection
                    
                    WIPView(
                        inProgressCount: inProgressCount,
                        maxActiveTasks: maxActiveTasks,
                        isFocusGuardEnabled: isFocusGuardEnabled,
                        blockedInProgressTask: blockedInProgressTask,
                        oldestInProgressTask: oldestInProgressTask,
                        nextPullTask: nextPullTask,
                        onReviewActiveTasks: { onSelectStatus?(.inProgress) }
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
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onAddTask?()
                } label: {
                    Image(systemName: "plus")
                        .font(AppStyle.Typography.bodyLarge)
                        .foregroundStyle(AppStyle.Colors.Status.todo)
                        .frame(width: AppStyle.Shapes.buttonSizeMedium, height: AppStyle.Shapes.buttonSizeMedium)
                }
                .buttonStyle(.glass)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Image(systemName: "square.3.layers.3d")
                .font(AppStyle.Typography.emptyIcon)
                .foregroundStyle(.secondary)

            Text("No tasks yet")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(.primary)

            Text("Add a task to populate your dashboard")
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppStyle.Spacing.emptyStateVerticalPadding)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.subtleText)

                    Text("\(doneCount) of \(totalCount) tasks")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.85)
                }

                progressBar
            }

            Spacer(minLength: 0)

            progressRing
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 22)
        .cardStyle(cornerRadius: AppStyle.Shapes.headerCornerRadius)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppStyle.Colors.track.opacity(0.65))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppStyle.Colors.Status.done.opacity(0.85),
                                AppStyle.Colors.Status.done
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(12, geo.size.width * donePercent))
                    .animation(.spring(duration: 0.9, bounce: 0.12), value: donePercent)
            }
        }
        .frame(maxWidth: 420)
        .frame(height: 10)
    }

    private var progressRing: some View {
        let ringSize: CGFloat = 96
        return ZStack {
            Circle()
                .stroke(AppStyle.Colors.track.opacity(0.6), lineWidth: 9)

            Circle()
                .trim(from: 0, to: donePercent)
                .stroke(
                    AppStyle.Colors.Status.done.opacity(0.16),
                    style: .init(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 4)

            Circle()
                .trim(from: 0, to: donePercent)
                .stroke(
                    LinearGradient(
                        colors: [AppStyle.Colors.Status.done.opacity(0.95), AppStyle.Colors.Status.done],
                        startPoint: .top,
                        endPoint: .bottomTrailing
                    ),
                    style: .init(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 1, bounce: 0.15), value: donePercent)

            VStack(spacing: 2) {
                Text("\(Int(donePercent * 100))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text("Complete")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.subtleText)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.statusRowGap) {
            HStack(alignment: .center) {
                sectionHeader("Status")
                Spacer()
                stackedBar
                    .frame(width: AppStyle.Spacing.stackedBarWidth)
            }

            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Tap a lane to open its tasks")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(AppStyle.Colors.subtleText)

            VStack(spacing: AppStyle.Spacing.none) {
                statusRow(status: .todo, count: todoCount, color: AppStyle.Colors.Status.todo, icon: "circle")
                
                dividerLine
                
                statusRow(status: .inProgress, count: inProgressCount, color: AppStyle.Colors.Status.inProgress, icon: "clock.fill", isHighlighted: true)
                
                dividerLine
                
                statusRow(status: .done, count: doneCount, color: AppStyle.Colors.Status.done, icon: "checkmark.circle.fill")
            }
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
    }

    private var dividerLine: some View {
        AppStyle.Colors.divider
            .frame(height: 1)
            .padding(.leading, AppStyle.Spacing.dividerLeadingCompact)
    }

    private func statusRow(status: TaskStatus, count: Int, color: Color, icon: String, isHighlighted: Bool = false) -> some View {
        let barRatio = totalCount > 0 ? Double(count) / Double(totalCount) : 0.0
        
        // Focus Guard logic
        let isWIPLimitReached = isFocusGuardEnabled && status == .inProgress && count >= maxActiveTasks
        let rowColor = isWIPLimitReached ? AppStyle.Colors.warning : color

        return Button {
            onSelectStatus?(status)
        } label: {
            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                Image(systemName: isWIPLimitReached ? "exclamationmark.triangle.fill" : icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(rowColor)
                    .frame(width: 24)

                Text(status.rawValue)
                    .font(.system(size: 20, weight: isHighlighted ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isHighlighted ? .primary : rowColor.opacity(0.85))
                    .frame(width: 112, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [rowColor, rowColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(AppStyle.Shapes.minBarWidth, geo.size.width * barRatio))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: barRatio)
                }
                .frame(height: AppStyle.Shapes.barHeightHighlighted)

                Text(count.formatted())
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(isHighlighted ? .primary : .secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .frame(width: 32, alignment: .trailing)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)
            }
            .padding(.horizontal, AppStyle.Spacing.cardPadding)
            .padding(.vertical, 18)
            .contentShape(.rect)
            .background {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.statusHighlightCornerRadius, style: .continuous)
                        .fill(rowColor.opacity(0.12))
                        .padding(.horizontal, AppStyle.Spacing.statusHighlightPaddingHorizontal)
                        .padding(.vertical, AppStyle.Spacing.statusHighlightPaddingVertical)
                }
            }
            .overlay(alignment: .trailing) {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.statusHighlightCornerRadius, style: .continuous)
                        .stroke(rowColor.opacity(0.16), lineWidth: 1)
                        .padding(.horizontal, AppStyle.Spacing.statusHighlightPaddingHorizontal)
                        .padding(.vertical, AppStyle.Spacing.statusHighlightPaddingVertical)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(status.rawValue), \(count) tasks")
        .accessibilityHint("Opens the \(status.rawValue) lane")
    }

    private var stackedBar: some View {
        let total = max(totalCount, 1)
        let todoRatio = CGFloat(todoCount) / CGFloat(total)
        let progRatio = CGFloat(inProgressCount) / CGFloat(total)
        let doneRatio = CGFloat(doneCount) / CGFloat(total)

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppStyle.Colors.track)

                HStack(spacing: AppStyle.Spacing.none) {
                    if todoCount > 0 {
                        Rectangle()
                            .fill(AppStyle.Colors.Status.todo)
                            .frame(width: geo.size.width * todoRatio)
                    }
                    if inProgressCount > 0 {
                        Rectangle()
                            .fill(isFocusGuardEnabled && inProgressCount >= maxActiveTasks ? AppStyle.Colors.warning : AppStyle.Colors.Status.inProgress)
                            .frame(width: geo.size.width * progRatio)
                    }
                    if doneCount > 0 {
                        Rectangle()
                            .fill(AppStyle.Colors.Status.done)
                            .frame(width: geo.size.width * doneRatio)
                    }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: AppStyle.Shapes.barHeight)
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
        let fillOpacity = isEmpty ? 0.04 : 0.14

        return VStack(spacing: AppStyle.Spacing.none) {
            VStack(spacing: AppStyle.Spacing.priorityCardVStackGap) {
                Text(count.formatted())
                    .font(AppStyle.Typography.priorityNumber)
                    .foregroundStyle(isEmpty ? .tertiary : .primary)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: AppStyle.Spacing.sectionHStackGap) {
                    Circle()
                        .fill(isEmpty ? .secondary.opacity(0.3) : tint)
                        .frame(width: AppStyle.Shapes.priorityDotSize, height: AppStyle.Shapes.priorityDotSize)
                    Text(priority)
                        .font(AppStyle.Typography.priorityLabelBold)
                        .foregroundStyle(isEmpty ? .tertiary : .primary)
                }
            }
            .padding(.vertical, AppStyle.Spacing.priorityVerticalPadding)
            .padding(.horizontal, AppStyle.Spacing.statusRowVerticalCompact)
        }
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    let fillHeight = dominanceRatio > 0
                        ? max(
                            AppStyle.Shapes.accentBarHeight,
                            geo.size.height * (0.18 + (0.52 * dominanceRatio))
                        )
                        : AppStyle.Shapes.accentBarHeight

                    tint
                        .opacity(isEmpty ? 0.18 : fillOpacity)
                        .frame(height: fillHeight)

                    Spacer(minLength: 0)
                }
            }
        }
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        .opacity(isEmpty ? 0.8 : 1.0)
    }

    // MARK: - Footer

    private var flowReviewSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Flow Review")

            VStack(spacing: 12) {
                flowReviewCard(
                    title: "Blocked Work",
                    count: blockedInProgressTask == nil ? 0 : allTasks.filter { $0.status == .inProgress && $0.isBlocked }.count,
                    tint: AppStyle.Colors.warning,
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

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(momentumHeadline)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(momentumMessage)
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        AppStyle.Colors.Status.done.opacity(0.14),
                        AppStyle.Colors.surface,
                        AppStyle.Colors.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                    .stroke(AppStyle.Colors.surfaceBorder, lineWidth: 1)
            )
        }
        .padding(.bottom, AppStyle.Spacing.emptyBottomSpacer)
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Flow Trends")

            HStack(spacing: 12) {
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

            HStack(spacing: 12) {
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
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(AppStyle.Typography.statusLabelHighlighted)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(count)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(tint)
                    }

                    Text(description)
                        .font(AppStyle.Typography.cardDate)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
        .buttonStyle(.plain)
    }

    private func momentumStatCard(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func trendCard(label: String, value: String, tint: Color, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(tint)

            Text(note)
                .font(AppStyle.Typography.cardDate)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
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
            .font(AppStyle.Typography.sectionTitle)
            .foregroundStyle(.secondary)
            .tracking(AppStyle.Typography.sectionTracking)
    }
}
