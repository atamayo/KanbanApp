import SwiftUI

struct ProgresView: View {
    let doneCount: Int
    let totalCount: Int
    var todoCount: Int? = nil
    var inProgressCount: Int? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var metrics: ProgressMetrics {
        ProgressMetrics(
            doneCount: doneCount,
            totalCount: totalCount,
            todoCount: todoCount,
            inProgressCount: inProgressCount
        )
    }

    var body: some View {
        Group {
            if metrics.isEmpty {
                emptyProgressContent
            } else {
                activeProgressContent
            }
        }
        .padding(.vertical, AppStyle.Spacing.progressCardVerticalPadding)
        .padding(.horizontal, AppStyle.Spacing.progressCardHorizontalPadding)
        .cardStyle(cornerRadius: AppStyle.Shapes.headerCornerRadius)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metrics.accessibilityLabel)
    }

    private var activeProgressContent: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            ProgressSectionLabel()

            topLayout

            ProgressBreakdown(lanes: metrics.breakdownLanes)
        }
    }

    private var emptyProgressContent: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.normal) {
            ProgressSummaryText(metrics: metrics)
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "plus.circle")
                    .font(AppStyle.Typography.iconHero)
                    .foregroundStyle(AppStyle.Colors.Status.todo.opacity(AppStyle.Opacity.accentForegroundMuted))
                    .frame(width: AppStyle.Shapes.iconBadgeSmall, height: AppStyle.Shapes.iconBadgeSmall)
                    .background(
                        AppStyle.Colors.Status.todo.opacity(AppStyle.Opacity.accentWashSubtle),
                        in: Circle()
                    )
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private var topLayout: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalLayout
        } else {
            horizontalLayout
        }
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
            ProgressDetailText(metrics: metrics)
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            ProgressRing(
                progress: metrics.progress,
                percentageText: metrics.percentageText,
                reduceMotion: reduceMotion
            )
            .frame(width: AppStyle.Shapes.progressRingSize, height: AppStyle.Shapes.progressRingSize)
            .layoutPriority(0)
            .fixedSize()
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            ProgressDetailText(metrics: metrics)
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            ProgressRing(
                progress: metrics.progress,
                percentageText: metrics.percentageText,
                reduceMotion: reduceMotion
            )
            .frame(width: AppStyle.Shapes.progressRingSize, height: AppStyle.Shapes.progressRingSize)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct ProgressSummaryText: View {
    let metrics: ProgressMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.progressTextGap) {
            ProgressSectionLabel()

            ProgressDetailText(metrics: metrics)
        }
        .layoutPriority(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProgressSectionLabel: View {
    var body: some View {
        Text("YOUR PROGRESS")
            .font(AppStyle.Typography.progressEyebrow)
            .foregroundStyle(AppStyle.Colors.subtleText)
            .tracking(AppStyle.Typography.sectionTracking)
            .lineLimit(1)
    }
}

private struct ProgressDetailText: View {
    let metrics: ProgressMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            Text(metrics.summaryText)
                .font(AppStyle.Typography.progressSummary)
                .foregroundStyle(AppStyle.Colors.primaryText)
                .contentTransition(.numericText())
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(metrics.insightText)
                .font(AppStyle.Typography.progressInsight)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProgressRing: View {
    let progress: Double
    let percentageText: String
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AppStyle.Colors.track.opacity(AppStyle.Opacity.subtleTrack),
                    lineWidth: AppStyle.Shapes.progressRingTrackStroke
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppStyle.Colors.Status.done.opacity(AppStyle.Opacity.accentBorder),
                    style: .init(lineWidth: AppStyle.Shapes.progressRingGlowStroke, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: AppStyle.Shapes.compactRingGlowBlur)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppStyle.Colors.Status.done.opacity(AppStyle.Opacity.accentForegroundEmphasized),
                            AppStyle.Colors.Status.done
                        ],
                        startPoint: .top,
                        endPoint: .bottomTrailing
                    ),
                    style: .init(lineWidth: AppStyle.Shapes.progressRingTrackStroke, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : AppStyle.Motion.ringProgress, value: progress)

            VStack(spacing: AppStyle.Spacing.micro) {
                Text(percentageText)
                    .font(AppStyle.Typography.ringPercentage)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(AppStyle.Typography.minimumScaleFactor)

                Text("Complete")
                    .font(AppStyle.Typography.ringCaption)
                    .foregroundStyle(AppStyle.Colors.subtleText)
                    .lineLimit(1)
                    .minimumScaleFactor(AppStyle.Typography.minimumScaleFactor)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ProgressBreakdown: View {
    let lanes: [ProgressLane]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stackedLayout
        } else {
            horizontalLayout
        }
    }

    private var horizontalLayout: some View {
        HStack(spacing: AppStyle.Spacing.none) {
            ForEach(Array(lanes.enumerated()), id: \.element.id) { index, lane in
                if index > 0 {
                    Spacer(minLength: AppStyle.Spacing.tight)
                    verticalDivider
                    Spacer(minLength: AppStyle.Spacing.tight)
                }

                ProgressBreakdownItem(lane: lane)
                    .layoutPriority(lane.label == "In Progress" ? 2 : 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityHidden(true)
    }

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            ForEach(lanes) { lane in
                ProgressBreakdownItem(lane: lane)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }

    private var verticalDivider: some View {
        AppStyle.Colors.divider
            .frame(width: AppStyle.Shapes.dividerHeight, height: AppStyle.Shapes.progressBreakdownDividerHeight)
    }
}

private struct ProgressBreakdownItem: View {
    let lane: ProgressLane

    var body: some View {
        HStack(spacing: AppStyle.Spacing.progressBreakdownItemGap) {
            Circle()
                .fill(lane.color)
                .frame(width: AppStyle.Shapes.dotSize, height: AppStyle.Shapes.dotSize)

            Text(lane.count.formatted())
                .font(AppStyle.Typography.progressBreakdownCount)
                .foregroundStyle(AppStyle.Colors.primaryText)
                .monospacedDigit()

            Text(lane.label)
                .font(AppStyle.Typography.progressBreakdownLabel)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct ProgressMetrics {
    let completedCount: Int
    let totalCount: Int
    let todoCount: Int
    let inProgressCount: Int
    let progress: Double

    init(doneCount: Int, totalCount: Int, todoCount: Int?, inProgressCount: Int?) {
        let safeTotalCount = max(totalCount, 0)
        let safeDoneCount = min(max(doneCount, 0), safeTotalCount)
        let safeTodoCount = max(todoCount ?? max(safeTotalCount - safeDoneCount, 0), 0)
        let safeInProgressCount = max(inProgressCount ?? 0, 0)

        self.completedCount = safeDoneCount
        self.totalCount = safeTotalCount
        self.todoCount = safeTodoCount
        self.inProgressCount = safeInProgressCount
        self.progress = safeTotalCount > 0 ? Double(safeDoneCount) / Double(safeTotalCount) : 0
    }

    var isEmpty: Bool {
        totalCount == 0
    }

    var percentage: Int {
        Int((progress * 100).rounded())
    }

    var percentageText: String {
        "\(percentage)%"
    }

    var summaryText: String {
        if totalCount == 0 {
            return "No tasks yet"
        }

        if completedCount == totalCount {
            return "All tasks completed"
        }

        return "\(completedCount.formatted()) of \(totalCount.formatted()) \(taskWord) completed"
    }

    var insightText: String {
        switch percentage {
        case 0 where totalCount == 0:
            return "Add your first task to start tracking progress."
        case 0:
            return "Move your first task to Done to build momentum."
        case 1...39:
            return "Good start — keep moving work toward Done."
        case 40...74:
            return "Momentum is building across your board."
        case 75...99:
            return "Almost there — close the remaining tasks."
        default:
            return "Board complete — all tasks are done."
        }
    }

    var accessibilityLabel: String {
        if isEmpty {
            return "Your progress. No tasks yet. Add your first task to start tracking progress."
        }

        return "Your progress. \(summaryText). \(percentage) percent complete. \(insightText) \(todoCount) to do, \(inProgressCount) in progress, \(completedCount) done."
    }

    var breakdownLanes: [ProgressLane] {
        [
            ProgressLane(label: "To Do", count: todoCount, color: AppStyle.Colors.Status.todo),
            ProgressLane(label: "In Progress", count: inProgressCount, color: AppStyle.Colors.Status.inProgress),
            ProgressLane(label: "Done", count: completedCount, color: AppStyle.Colors.Status.done)
        ]
    }

    private var taskWord: String {
        totalCount == 1 ? "task" : "tasks"
    }
}

private struct ProgressLane: Identifiable {
    let label: String
    let count: Int
    let color: Color

    var id: String { label }
}

private struct ProgresPreviewContainer: View {
    let todoCount: Int
    let inProgressCount: Int
    let doneCount: Int

    private var totalCount: Int {
        todoCount + inProgressCount + doneCount
    }

    init(todoCount: Int, inProgressCount: Int, doneCount: Int) {
        self.todoCount = todoCount
        self.inProgressCount = inProgressCount
        self.doneCount = doneCount
    }

    var body: some View {
        ProgresView(
            doneCount: doneCount,
            totalCount: totalCount,
            todoCount: todoCount,
            inProgressCount: inProgressCount
        )
            .padding(AppStyle.Spacing.outerHorizontal)
            .background(AppStyle.Colors.background)
    }
}

#Preview("Progress No Tasks") {
    ProgresPreviewContainer(todoCount: 0, inProgressCount: 0, doneCount: 0)
}

#Preview("Progress None Complete") {
    ProgresPreviewContainer(todoCount: 2, inProgressCount: 1, doneCount: 0)
}

#Preview("Progress Low") {
    ProgresPreviewContainer(todoCount: 1, inProgressCount: 1, doneCount: 1)
}

#Preview("Progress Mid") {
    ProgresPreviewContainer(todoCount: 1, inProgressCount: 0, doneCount: 2)
}

#Preview("Progress Complete") {
    ProgresPreviewContainer(todoCount: 0, inProgressCount: 0, doneCount: 3)
}

#Preview("Progress Large Dynamic Type") {
    ProgresPreviewContainer(todoCount: 1, inProgressCount: 1, doneCount: 1)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Progress Dark Mode") {
    ProgresPreviewContainer(todoCount: 1, inProgressCount: 1, doneCount: 1)
        .preferredColorScheme(.dark)
}
