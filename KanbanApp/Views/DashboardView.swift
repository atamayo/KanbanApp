import SwiftUI
struct DashboardView: View {
    let allTasks: [TaskItem]
    var onSelectStatus: ((TaskStatus) -> Void)? = nil
    var onOpenWIPCoach: (() -> Void)? = nil
    
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3

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

    private var doneThisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allTasks.filter {
            $0.status == .done && ($0.finalizedAt ?? $0.updatedAt) >= weekAgo
        }.count
    }

    private var tasksWithCompletionCriteria: Int {
        currentTasks.filter { !$0.completionCriteria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if allTasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppStyle.Spacing.compactSectionSpacing) {
                    ProgresView(
                        doneCount: doneCount,
                        totalCount: totalCount,
                        todoCount: todoCount,
                        inProgressCount: inProgressCount
                    )
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
                        onOpenCoach: { onOpenWIPCoach?() }
                    )
                    
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
                priorityCard(priority: .high, count: count(priority: .high), tint: AppStyle.Colors.Priority.high)
                priorityCard(priority: .medium, count: count(priority: .medium), tint: AppStyle.Colors.Priority.medium)
                priorityCard(priority: .low, count: count(priority: .low), tint: AppStyle.Colors.Priority.low)
            }
        }
    }

    private func priorityCard(priority: TaskPriority, count: Int, tint: Color) -> some View {
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
                    Text(priority.localizedName)
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

    // MARK: - Shared

    private var momentumHeadline: String {
        if doneThisWeekCount >= 5 {
            return String(localized: "Strong finishing rhythm.")
        }
        if doneThisWeekCount > 0 {
            return String(localized: "Momentum is visible.")
        }
        return String(localized: "The next finished task changes the board.")
    }

    private var momentumMessage: String {
        if doneThisWeekCount >= 5 {
            return String(localized: "You are turning work into done consistently. Protect that rhythm by keeping WIP tight.")
        }
        if doneThisWeekCount > 0 {
            return String(localized: "Every completed task frees attention and opens space for the next pull.")
        }
        return String(localized: "Close one task and you free a focus slot, strengthen the Done column, and make progress feel real again.")
    }

    private func momentumStatCard(label: LocalizedStringKey, value: String, tint: Color) -> some View {
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

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .sectionHeaderStyle()
    }
}
