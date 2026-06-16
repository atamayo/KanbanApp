import SwiftData
import SwiftUI

struct WIPCoachView: View {
    let allTasks: [TaskItem]
    let maxActiveTasks: Int
    let isFocusGuardEnabled: Bool
    let onReviewActiveTasks: () -> Void
    let onReviewToDoTasks: () -> Void

    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0
    @AppStorage("taskAgingNotificationDayThreshold") private var taskAgingNotificationDayThreshold = 3
    @AppStorage("taskStalledNotificationDayThreshold") private var taskStalledNotificationDayThreshold = 5
    @Environment(\.modelContext) private var modelContext
    @State private var activeTask: TaskItem?
    @State private var isTaskChatPresented = false
    @State private var taskChatMessages: [TaskChatMessage] = []
    @State private var generatedCoachCopy: WIPCoachCopyDraft?
    @State private var generatedCoachCopySignature: String?

    private var recommendation: WIPCoachRecommendation {
        WIPCoachEngine.evaluate(
            tasks: allTasks,
            maxActiveTasks: maxActiveTasks,
            isFocusGuardEnabled: isFocusGuardEnabled
        )
    }

    private var accentColor: Color {
        switch recommendation.pressure {
        case .hasRoom:
            return AppStyle.Colors.Status.todo
        case .healthy:
            return AppStyle.Colors.Status.done
        case .nearLimit, .atLimit:
            return AppStyle.Colors.warning
        case .overloaded:
            return AppStyle.Colors.Priority.high
        case .blocked:
            return AppStyle.Colors.blocked
        }
    }

    private var coachCopyRequest: WIPCoachCopyRequest {
        WIPCoachCopyRequest(recommendation: recommendation)
    }

    private var validGeneratedCopy: WIPCoachCopyDraft? {
        guard generatedCoachCopySignature == coachCopyRequest.signature else { return nil }
        return generatedCoachCopy
    }

    private var taskChatContext: TaskChatContext {
        TaskChatContext(
            recommendation: recommendation,
            headline: displayedHeadline,
            reason: displayedRecommendationReason
        )
    }

    private var displayedHeadline: String {
        validGeneratedCopy?.headline.trimmedNonEmpty ?? recommendation.headline
    }

    private var displayedBody: String {
        validGeneratedCopy?.body.trimmedNonEmpty ?? recommendation.body
    }

    private var displayedRecommendationReason: String {
        validGeneratedCopy?.recommendationReason.trimmedNonEmpty ?? recommendation.reason
    }

    private var blockedInProgressTask: TaskItem? {
        allTasks
            .filter { $0.status == .inProgress && $0.isBlocked }
            .sorted { $0.updatedAt < $1.updatedAt }
            .first
    }

    private var agingSummary: TaskAgingSummary {
        TaskAgingEvaluator.evaluate(
            tasks: allTasks,
            now: Date(),
            agingDays: taskAgingNotificationDayThreshold,
            stalledDays: taskStalledNotificationDayThreshold
        )
    }

    private var agingInProgressTasks: [TaskItem] {
        agingSummary.agingTasks
    }

    private var stalledInProgressTasks: [TaskItem] {
        agingSummary.stalledTasks
    }

    private var toDoWaitingSummary: ToDoWaitingSummary {
        TaskAgingEvaluator.evaluateToDoWaiting(
            tasks: allTasks,
            now: Date()
        )
    }

    private var staleToDoTasks: [TaskItem] {
        toDoWaitingSummary.staleTasks
    }

    private var oldestToDoTask: TaskItem? {
        toDoWaitingSummary.oldestTask
    }

    private var oldestInProgressTask: TaskItem? {
        allTasks
            .filter { $0.status == .inProgress && !$0.isBlocked }
            .sorted { TaskAgingEvaluator.activeSince(for: $0) < TaskAgingEvaluator.activeSince(for: $1) }
            .first
    }

    private var doneThisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allTasks.filter {
            $0.status == .done && ($0.finalizedAt ?? $0.updatedAt) >= weekAgo
        }.count
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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                    summaryCard
                    recommendationSection
                    alternativesSection
                    activeWorkSection
                    flowReviewSection
                    trendSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
                .padding(.top, AppStyle.Spacing.outerVertical)
                .padding(.bottom, AppStyle.Spacing.outerVertical + AppStyle.Spacing.emptyBottomSpacer)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            taskChatButton
                .padding(.trailing, AppStyle.Spacing.fabPadding)
                .padding(.bottom, AppStyle.Spacing.fabPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.Colors.background)
        .navigationTitle("WIP Coach")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeTask) { task in
            TaskDetailView(task: task)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isTaskChatPresented) {
            TaskChatView(tasks: allTasks, context: taskChatContext, messages: $taskChatMessages)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task(id: coachCopyRequest.signature) {
            await refreshGeneratedCoachCopy(for: coachCopyRequest)
        }
    }

    private var taskChatButton: some View {
        Button {
            isTaskChatPresented = true
        } label: {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(AppStyle.Typography.fabIcon)
                .foregroundStyle(AppStyle.Colors.inverseText)
                .frame(width: AppStyle.Shapes.fabSize, height: AppStyle.Shapes.fabSize)
                .background(AppStyle.Colors.fabGradient, in: Circle())
                .shadow(
                    color: AppStyle.Colors.fabShadow,
                    radius: AppStyle.Shapes.fabShadowRadius,
                    x: AppStyle.Shapes.fabShadowX,
                    y: AppStyle.Shapes.fabShadowY
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask about tasks")
    }

    private var flowReviewSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            Text("Flow Review")
                .sectionHeaderStyle()

            VStack(spacing: AppStyle.Spacing.statusRowGap) {
                flowReviewCard(
                    title: "Blocked Work",
                    count: blockedInProgressTask == nil ? 0 : allTasks.filter { $0.status == .inProgress && $0.isBlocked }.count,
                    tint: AppStyle.Colors.blocked,
                    icon: "pause.circle.fill",
                    description: blockedInProgressTask == nil ? String(localized: "No active blockers right now.") : String(localized: "Blocked tasks need attention before more work is pulled."),
                    action: onReviewActiveTasks
                )

                flowReviewCard(
                    title: "Waiting To Do",
                    count: staleToDoTasks.count,
                    tint: AppStyle.Colors.Status.todo,
                    icon: "clock.badge.exclamationmark",
                    description: waitingToDoDescription,
                    action: onReviewToDoTasks
                )

                flowReviewCard(
                    title: "Aging Tasks",
                    count: agingInProgressTasks.count,
                    tint: AppStyle.Colors.Priority.medium,
                    icon: "clock.badge.exclamationmark",
                    description: agingInProgressTasks.isEmpty ? String(localized: "Nothing is drifting yet.") : String(localized: "These tasks are staying active long enough to risk drag."),
                    action: onReviewActiveTasks
                )

                flowReviewCard(
                    title: "Stalled Tasks",
                    count: stalledInProgressTasks.count,
                    tint: AppStyle.Colors.Priority.high,
                    icon: "exclamationmark.circle.fill",
                    description: stalledInProgressTasks.isEmpty ? String(localized: "No stalled work right now.") : String(localized: "These tasks have sat too long in progress and may need a decision."),
                    action: onReviewActiveTasks
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            Text("Flow Trends")
                .sectionHeaderStyle()

            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                trendCard(
                    label: "Avg Days To Done",
                    value: averageDaysToDone.map { String(format: "%.1f", $0) } ?? "-",
                    tint: AppStyle.Colors.Status.done,
                    note: averageDaysToDone == nil ? String(localized: "Need completed in-progress tasks") : String(localized: "From In Progress to Done")
                )

                trendCard(
                    label: "Done This Week",
                    value: "\(doneThisWeekCount)",
                    tint: AppStyle.Colors.Status.todo,
                    note: String(localized: "Recent finish rate")
                )
            }

            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                trendCard(
                    label: "WIP Limit Hits",
                    value: "\(wipLimitHitCount)",
                    tint: AppStyle.Colors.warning,
                    note: String(localized: "Times flow pushed back")
                )

                trendCard(
                    label: "Active Age",
                    value: oldestInProgressTask.map { activeAgeText(for: $0) } ?? "-",
                    tint: AppStyle.Colors.Status.inProgress,
                    note: oldestInProgressTask == nil ? String(localized: "No active task running") : String(localized: "Oldest active task")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.normal) {
            Label(displayedHeadline, systemImage: "scope")
                .font(AppStyle.Typography.metricMedium)
                .foregroundStyle(AppStyle.Colors.primaryText)

            Text(displayedBody)
                .font(AppStyle.Typography.formFooter)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                statsRow
                VStack(spacing: AppStyle.Spacing.statusRowGap) {
                    statTile("Active", "\(recommendation.stats.activeCount)/\(recommendation.stats.wipLimit)")
                    statTile("Slots Left", "\(recommendation.stats.slotsLeft)")
                    statTile("Blocked", "\(recommendation.stats.blockedCount)")
                    statTile("Ready", "\(recommendation.stats.readyCount)")
                }
            }
        }
        .padding(AppStyle.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accentCardStyle(tint: accentColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Work in progress review. \(recommendation.stats.activeCount) of \(recommendation.stats.wipLimit) tasks active. \(recommendation.stats.slotsLeft) slots left. \(recommendation.stats.blockedCount) blocked tasks. \(recommendation.stats.readyCount) ready tasks."))
    }

    private var statsRow: some View {
        HStack(spacing: AppStyle.Spacing.statusRowGap) {
            statTile("Active", "\(recommendation.stats.activeCount)/\(recommendation.stats.wipLimit)")
            statTile("Slots Left", "\(recommendation.stats.slotsLeft)")
            statTile("Blocked", "\(recommendation.stats.blockedCount)")
            statTile("Ready", "\(recommendation.stats.readyCount)")
        }
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            Text("Recommended Action")
                .sectionHeaderStyle()

            VStack(alignment: .leading, spacing: AppStyle.Spacing.normal) {
                Text(recommendation.label)
                    .font(AppStyle.Typography.pillLabel)
                    .foregroundStyle(accentColor)
                    .textCase(.uppercase)

                Text(recommendation.recommendedTask?.title ?? String(localized: "Your board is clear"))
                    .font(AppStyle.Typography.cardTitle)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(displayedRecommendationReason)
                    .font(AppStyle.Typography.formFooter)
                    .foregroundStyle(AppStyle.Colors.secondaryText)

                actionButtons
            }
            .padding(AppStyle.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch recommendation.action {
        case .pullNextTask:
            if let task = recommendation.recommendedTask {
                Button {
                    pullTask(task)
                } label: {
                    Label("Pull Task", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.iconBadgeSmall)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .accessibilityHint("Moves this task to In Progress.")
            }
        case .focusCurrentTask:
            if let task = recommendation.recommendedTask {
                Button {
                    activeTask = task
                } label: {
                    Label("Focus Task", systemImage: "scope")
                        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.iconBadgeSmall)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .accessibilityHint("Opens the recommended active task.")
            }
        case .unblockTask:
            if let task = recommendation.recommendedTask {
                Button {
                    activeTask = task
                } label: {
                    Label("Open Blocked Task", systemImage: "pause.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.iconBadgeSmall)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .accessibilityHint("Opens the blocked task so you can update it.")
            }
        case .reduceWIP:
            Button(action: onReviewActiveTasks) {
                Label("Review Active Tasks", systemImage: "tray.full.fill")
                    .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.iconBadgeSmall)
            }
            .buttonStyle(.borderedProminent)
            .tint(accentColor)
            .accessibilityHint("Opens the active work lane.")
        case .breakDownTask:
            if let task = recommendation.recommendedTask {
                Button {
                    activeTask = task
                } label: {
                    Label("Break Down Task", systemImage: "list.bullet.indent")
                        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.iconBadgeSmall)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
            }
        case .noActionNeeded:
            EmptyView()
        }
    }

    @ViewBuilder
    private var alternativesSection: some View {
        if !recommendation.readyAlternatives.isEmpty {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
                Text("Ready Alternatives")
                    .sectionHeaderStyle()

                VStack(spacing: AppStyle.Spacing.statusRowGap) {
                    ForEach(recommendation.readyAlternatives, id: \.task.id) { candidate in
                        taskRow(
                            title: candidate.task.title,
                            subtitle: candidate.reason,
                            icon: "circle",
                            tint: AppStyle.Colors.Status.todo
                        ) {
                            activeTask = candidate.task
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var activeWorkSection: some View {
        if !recommendation.activeTasks.isEmpty {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
                Text("Active Work")
                    .sectionHeaderStyle()

                VStack(spacing: AppStyle.Spacing.statusRowGap) {
                    ForEach(recommendation.activeTasks.prefix(3)) { task in
                        taskRow(
                            title: task.title,
                            subtitle: task.isBlocked ? String(localized: "Blocked") : task.lastStatusChange.formatted(.relative(presentation: .named)),
                            icon: task.isBlocked ? "pause.circle.fill" : "clock.fill",
                            tint: task.isBlocked ? AppStyle.Colors.blocked : AppStyle.Colors.Status.inProgress
                        ) {
                            activeTask = task
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statTile(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            Text(label)
                .font(AppStyle.Typography.statLabel)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Text(value)
                .font(AppStyle.Typography.metricSmall)
                .foregroundStyle(AppStyle.Colors.primaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, AppStyle.Spacing.regular)
        .padding(.vertical, AppStyle.Spacing.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(AppStyle.Opacity.accentWash), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
    }

    private func taskRow(title: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AppStyle.Spacing.regular) {
                Image(systemName: icon)
                    .font(AppStyle.Typography.iconSmall)
                    .foregroundStyle(tint)
                    .frame(width: AppStyle.Spacing.iconFrameWidthMedium)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                    Text(title)
                        .font(AppStyle.Typography.cardTitle)
                        .foregroundStyle(AppStyle.Colors.primaryText)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(AppStyle.Typography.cardDate)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                }

                Spacer(minLength: AppStyle.Spacing.none)

                Image(systemName: "chevron.right")
                    .font(AppStyle.Typography.iconSmall)
                    .foregroundStyle(AppStyle.Colors.tertiaryText)
                    .accessibilityHidden(true)
            }
            .padding(AppStyle.Spacing.compactCardPadding)
            .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.iconBadgeSmall, alignment: .leading)
            .background(AppStyle.Colors.spotlightSurface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Opens task details.")
    }

    private func flowReviewCard(title: LocalizedStringKey, count: Int, tint: Color, icon: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var waitingToDoDescription: String {
        guard let oldestToDoTask else {
            return String(localized: "No To Do tasks are waiting right now.")
        }

        let age = toDoAgeText(for: oldestToDoTask)
        if staleToDoTasks.isEmpty {
            return String(localized: "Oldest To Do task: \(oldestToDoTask.title), waiting \(age).")
        }
        return String(localized: "Oldest waiting task: \(oldestToDoTask.title), waiting \(age).")
    }

    private func trendCard(label: LocalizedStringKey, value: String, tint: Color, note: String) -> some View {
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
        let activeSince = TaskAgingEvaluator.activeSince(for: task)
        return TaskAgingEvaluator.shortDurationText(for: Date().timeIntervalSince(activeSince))
    }

    private func toDoAgeText(for task: TaskItem) -> String {
        let toDoSince = TaskAgingEvaluator.toDoSince(for: task)
        return TaskAgingEvaluator.shortDurationText(for: Date().timeIntervalSince(toDoSince))
    }

    private func pullTask(_ task: TaskItem) {
        guard recommendation.action == .pullNextTask, task.status == .todo, recommendation.stats.slotsLeft > 0 else { return }

        let nextOrder = (allTasks.filter { $0.status == .inProgress }.map(\.order).max() ?? -1) + 1
        task.status = .inProgress
        task.order = nextOrder
        task.updatedAt = Date()
        try? modelContext.save()
        activeTask = task
    }

    @MainActor
    private func refreshGeneratedCoachCopy(for request: WIPCoachCopyRequest) async {
        generatedCoachCopy = nil
        generatedCoachCopySignature = nil

        guard case .available = WIPCoachCopyGenerator.availability else { return }

        do {
            let copy = try await WIPCoachCopyGenerator.generate(for: request)
            guard request.signature == coachCopyRequest.signature else { return }
            guard copy.hasUsableContent else { return }

            generatedCoachCopy = copy
            generatedCoachCopySignature = request.signature
        } catch {
            generatedCoachCopy = nil
            generatedCoachCopySignature = nil
        }
    }
}

#Preview("WIP Coach") {
    NavigationStack {
        WIPCoachView(
            allTasks: WIPPreviewData.overloaded,
            maxActiveTasks: 3,
            isFocusGuardEnabled: true,
            onReviewActiveTasks: {},
            onReviewToDoTasks: {}
        )
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
