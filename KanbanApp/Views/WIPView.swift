import SwiftData
import SwiftUI

struct WIPView: View {
    let allTasks: [TaskItem]
    let maxActiveTasks: Int
    let isFocusGuardEnabled: Bool
    let onReviewActiveTasks: () -> Void
    let onOpenTask: (TaskItem) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isShowingCoachReview = false
    @State private var coachReviewDetent: PresentationDetent = .large
    @State private var pendingTaskToOpen: TaskItem?
    @State private var shouldReviewActiveTasksAfterDismiss = false

    private var recommendation: WIPCoachRecommendation {
        WIPCoachEngine.evaluate(
            tasks: allTasks,
            maxActiveTasks: maxActiveTasks,
            isFocusGuardEnabled: isFocusGuardEnabled
        )
    }

    private var wipAccentColor: Color {
        color(for: recommendation.pressure)
    }

    private var wipIconName: String {
        switch recommendation.pressure {
        case .hasRoom, .healthy:
            return "scope"
        case .nearLimit:
            return "gauge.medium"
        case .atLimit:
            return "gauge.high"
        case .overloaded:
            return "flame.fill"
        case .blocked:
            return "pause.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            Text("WIP Pressure")
                .sectionHeaderStyle()

            VStack(alignment: .leading, spacing: AppStyle.Spacing.comfortable) {
                header
                stats
                recommendationCard
                ctaButton
            }
            .padding(AppStyle.Spacing.heroPadding)
            .accentCardStyle(
                tint: wipAccentColor,
                fillOpacity: recommendation.pressure == .overloaded ? AppStyle.Opacity.accentFillMuted : AppStyle.Opacity.accentWashStrong
            )
            .shadow(
                color: wipAccentColor.opacity(AppStyle.Opacity.restingShadow),
                radius: AppStyle.Shapes.columnShadowRadius,
                x: AppStyle.Spacing.none,
                y: AppStyle.Spacing.tight
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilitySummary)
        }
        .sheet(isPresented: $isShowingCoachReview) {
            WIPCoachReviewSheet(
                recommendation: recommendation,
                accentColor: wipAccentColor,
                onPullTask: pullTask,
                onOpenTask: queueOpenTask,
                onReviewActiveTasks: queueReviewActiveTasks
            )
            .presentationDetents([.large], selection: $coachReviewDetent)
            .presentationDragIndicator(.visible)
        }
        .onChange(of: isShowingCoachReview) { _, isPresented in
            guard !isPresented else { return }

            if let pendingTaskToOpen {
                self.pendingTaskToOpen = nil
                onOpenTask(pendingTaskToOpen)
            } else if shouldReviewActiveTasksAfterDismiss {
                shouldReviewActiveTasksAfterDismiss = false
                onReviewActiveTasks()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.normal) {
            ZStack {
                Circle()
                    .fill(wipAccentColor.opacity(AppStyle.Opacity.accentWashSelected))
                    .frame(width: AppStyle.Shapes.iconBadgeLarge, height: AppStyle.Shapes.iconBadgeLarge)

                Image(systemName: wipIconName)
                    .font(AppStyle.Typography.iconHero)
                    .foregroundStyle(wipAccentColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: AppStyle.Spacing.tight) {
                Text(recommendation.headline)
                    .font(AppStyle.Typography.metricMedium)
                    .foregroundStyle(AppStyle.Colors.primaryText)

                Text(recommendation.body)
                    .font(AppStyle.Typography.formFooter)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var stats: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                statPill(
                    label: "Active",
                    value: "\(recommendation.stats.activeCount)/\(recommendation.stats.wipLimit)",
                    tint: wipAccentColor
                )

                statPill(
                    label: "Slots Left",
                    value: "\(recommendation.stats.slotsLeft)",
                    tint: recommendation.stats.slotsLeft == 0 ? AppStyle.Colors.warning : AppStyle.Colors.Status.todo
                )
            }

            VStack(spacing: AppStyle.Spacing.statusRowGap) {
                statPill(
                    label: "Active",
                    value: "\(recommendation.stats.activeCount)/\(recommendation.stats.wipLimit)",
                    tint: wipAccentColor
                )

                statPill(
                    label: "Slots Left",
                    value: "\(recommendation.stats.slotsLeft)",
                    tint: recommendation.stats.slotsLeft == 0 ? AppStyle.Colors.warning : AppStyle.Colors.Status.todo
                )
            }
        }
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            Text(recommendation.label)
                .font(AppStyle.Typography.pillLabel)
                .foregroundStyle(wipAccentColor)
                .textCase(.uppercase)

            Text(recommendation.recommendedTask?.title ?? "Your board is clear")
                .font(AppStyle.Typography.cardTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)
                .lineLimit(2)

            Text(recommendation.recommendedTask == nil ? "No ready tasks need attention right now" : recommendation.reason)
                .font(AppStyle.Typography.cardDate)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.Colors.spotlightSurface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
    }

    private var ctaButton: some View {
        Button {
            isShowingCoachReview = true
        } label: {
            HStack {
                Text(recommendation.ctaTitle)
                Spacer()
                Image(systemName: "arrow.right")
                    .accessibilityHidden(true)
            }
            .font(AppStyle.Typography.buttonLabel)
            .foregroundStyle(primaryCTAUsesFill ? AppStyle.Colors.inverseText : wipAccentColor)
            .padding(.horizontal, AppStyle.Spacing.normal)
            .padding(.vertical, AppStyle.Spacing.regular)
            .frame(minHeight: AppStyle.Shapes.iconBadgeSmall)
            .background(
                primaryCTAUsesFill
                ? AnyShapeStyle(LinearGradient(colors: [wipAccentColor, wipAccentColor.opacity(AppStyle.Opacity.accentForegroundMuted)], startPoint: .leading, endPoint: .trailing))
                : AnyShapeStyle(AppStyle.Colors.spotlightSurface),
                in: RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(recommendation.ctaTitle)
        .accessibilityHint("Opens a detailed recommendation.")
    }

    private var primaryCTAUsesFill: Bool {
        switch recommendation.action {
        case .focusCurrentTask, .unblockTask, .reduceWIP:
            return true
        case .pullNextTask, .breakDownTask, .noActionNeeded:
            return false
        }
    }

    private var accessibilitySummary: String {
        let taskSummary = recommendation.recommendedTask.map { "Recommended task: \($0.title)." } ?? "No recommended task."
        return "Work in progress pressure. \(recommendation.headline) \(recommendation.stats.activeCount) of \(recommendation.stats.wipLimit) tasks active. \(recommendation.stats.slotsLeft) slots left. \(recommendation.label.capitalized). \(taskSummary)"
    }

    private func statPill(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            Text(label)
                .font(AppStyle.Typography.statLabel)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Text(value)
                .font(AppStyle.Typography.metricMedium)
                .foregroundStyle(AppStyle.Colors.primaryText)
        }
        .padding(.horizontal, AppStyle.Spacing.regular)
        .padding(.vertical, AppStyle.Spacing.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(AppStyle.Opacity.accentWash), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
    }

    private func pullTask(_ task: TaskItem) {
        guard recommendation.action == .pullNextTask, task.status == .todo, recommendation.stats.slotsLeft > 0 else { return }

        let nextOrder = (allTasks.filter { $0.status == .inProgress }.map(\.order).max() ?? -1) + 1
        task.status = .inProgress
        task.order = nextOrder
        task.updatedAt = Date()
        try? modelContext.save()
        queueOpenTask(task)
    }

    private func queueOpenTask(_ task: TaskItem) {
        pendingTaskToOpen = task
    }

    private func queueReviewActiveTasks() {
        shouldReviewActiveTasksAfterDismiss = true
    }

    private func color(for pressure: WIPPressureLevel) -> Color {
        switch pressure {
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
}

private struct WIPCoachReviewSheet: View {
    let recommendation: WIPCoachRecommendation
    let accentColor: Color
    let onPullTask: (TaskItem) -> Void
    let onOpenTask: (TaskItem) -> Void
    let onReviewActiveTasks: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                    summaryCard
                    recommendationSection
                    alternativesSection
                    activeWorkSection
                }
                .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
                .padding(.vertical, AppStyle.Spacing.outerVertical)
            }
            .background(AppStyle.Colors.background)
            .navigationTitle("WIP Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.normal) {
            Label(recommendation.headline, systemImage: "scope")
                .font(AppStyle.Typography.metricMedium)
                .foregroundStyle(AppStyle.Colors.primaryText)

            Text(recommendation.body)
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
        .accentCardStyle(tint: accentColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Work in progress review. \(recommendation.stats.activeCount) of \(recommendation.stats.wipLimit) tasks active. \(recommendation.stats.slotsLeft) slots left. \(recommendation.stats.blockedCount) blocked tasks. \(recommendation.stats.readyCount) ready tasks.")
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

                Text(recommendation.recommendedTask?.title ?? "Your board is clear")
                    .font(AppStyle.Typography.cardTitle)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(recommendation.recommendedTask == nil ? "No ready tasks need attention right now." : recommendation.reason)
                    .font(AppStyle.Typography.formFooter)
                    .foregroundStyle(AppStyle.Colors.secondaryText)

                actionButtons
            }
            .padding(AppStyle.Spacing.large)
            .cardStyle()
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch recommendation.action {
        case .pullNextTask:
            if let task = recommendation.recommendedTask {
                Button {
                    dismiss()
                    onPullTask(task)
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
                    dismiss()
                    onOpenTask(task)
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
                    dismiss()
                    onOpenTask(task)
                } label: {
                    Label("Open Blocked Task", systemImage: "pause.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.iconBadgeSmall)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .accessibilityHint("Opens the blocked task so you can update it.")
            }
        case .reduceWIP:
            Button {
                dismiss()
                onReviewActiveTasks()
            } label: {
                Label("Review Active Tasks", systemImage: "tray.full.fill")
                    .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.iconBadgeSmall)
            }
            .buttonStyle(.borderedProminent)
            .tint(accentColor)
            .accessibilityHint("Opens the active work lane.")
        case .breakDownTask:
            if let task = recommendation.recommendedTask {
                Button {
                    dismiss()
                    onOpenTask(task)
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
                            dismiss()
                            onOpenTask(candidate.task)
                        }
                    }
                }
            }
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
                            subtitle: task.isBlocked ? "Blocked" : task.lastStatusChange.formatted(.relative(presentation: .named)),
                            icon: task.isBlocked ? "pause.circle.fill" : "clock.fill",
                            tint: task.isBlocked ? AppStyle.Colors.blocked : AppStyle.Colors.Status.inProgress
                        ) {
                            dismiss()
                            onOpenTask(task)
                        }
                    }
                }
            }
        }
    }

    private func statTile(_ label: String, _ value: String) -> some View {
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
}

#Preview("WIP Has Room") {
    WIPView(
        allTasks: WIPPreviewData.hasRoom,
        maxActiveTasks: 3,
        isFocusGuardEnabled: true,
        onReviewActiveTasks: {},
        onOpenTask: { _ in }
    )
    .padding()
    .background(AppStyle.Colors.background)
}

#Preview("WIP At Limit") {
    WIPView(
        allTasks: WIPPreviewData.atLimit,
        maxActiveTasks: 3,
        isFocusGuardEnabled: true,
        onReviewActiveTasks: {},
        onOpenTask: { _ in }
    )
    .padding()
    .background(AppStyle.Colors.background)
}

#Preview("WIP Blocked") {
    WIPView(
        allTasks: WIPPreviewData.blocked,
        maxActiveTasks: 3,
        isFocusGuardEnabled: true,
        onReviewActiveTasks: {},
        onOpenTask: { _ in }
    )
    .padding()
    .background(AppStyle.Colors.background)
}

#Preview("WIP Overloaded Large Type") {
    WIPView(
        allTasks: WIPPreviewData.overloaded,
        maxActiveTasks: 3,
        isFocusGuardEnabled: true,
        onReviewActiveTasks: {},
        onOpenTask: { _ in }
    )
    .padding()
    .background(AppStyle.Colors.background)
    .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
}

#Preview("WIP No Ready Dark") {
    WIPView(
        allTasks: WIPPreviewData.noReady,
        maxActiveTasks: 4,
        isFocusGuardEnabled: true,
        onReviewActiveTasks: {},
        onOpenTask: { _ in }
    )
    .padding()
    .background(AppStyle.Colors.background)
    .preferredColorScheme(.dark)
}

private enum WIPPreviewData {
    static var hasRoom: [TaskItem] {
        [
            task("Plan sprint goals", status: .todo, priority: .high, order: 0),
            task("Polish voice capture", status: .todo, priority: .medium, order: 1),
            task("Refine onboarding flow", status: .inProgress, priority: .medium, order: 0)
        ]
    }

    static var atLimit: [TaskItem] {
        [
            task("Plan sprint goals", status: .todo, priority: .high, order: 0),
            task("Refine onboarding flow", status: .inProgress, priority: .medium, order: 0),
            task("Validate swipe actions", status: .inProgress, priority: .high, order: 1),
            task("Update Dashboard copy", status: .inProgress, priority: .low, order: 2)
        ]
    }

    static var blocked: [TaskItem] {
        [
            task("Resolve account sync blocker", status: .inProgress, priority: .high, isBlocked: true, order: 0),
            task("Refine onboarding flow", status: .inProgress, priority: .medium, order: 1),
            task("Plan sprint goals", status: .todo, priority: .high, order: 0)
        ]
    }

    static var overloaded: [TaskItem] {
        [
            task("Resolve account sync blocker", status: .inProgress, priority: .high, order: 0),
            task("Refine onboarding flow", status: .inProgress, priority: .medium, order: 1),
            task("Validate swipe actions", status: .inProgress, priority: .high, order: 2),
            task("Update Dashboard copy", status: .inProgress, priority: .low, order: 3)
        ]
    }

    static var noReady: [TaskItem] {
        [
            task("Refine onboarding flow", status: .inProgress, priority: .medium, order: 0),
            task("Ship search improvements", status: .done, priority: .low, order: 0)
        ]
    }

    private static func task(
        _ title: String,
        status: TaskStatus,
        priority: TaskPriority,
        isBlocked: Bool = false,
        order: Int
    ) -> TaskItem {
        TaskItem(
            title: title,
            description: "A focused task with enough context for the WIP coach preview.",
            completionCriteria: "Clear finish criteria",
            status: status,
            priority: priority,
            isBlocked: isBlocked,
            order: order
        )
    }
}
