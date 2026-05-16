import SwiftUI

struct StatusView: View {
    let todoCount: Int
    let inProgressCount: Int
    let doneCount: Int
    let totalCount: Int
    let maxActiveTasks: Int
    let isFocusGuardEnabled: Bool
    var selectedStatus: TaskStatus? = nil
    var onSelectStatus: ((TaskStatus) -> Void)? = nil

    private var lanes: [StatusLane] {
        [
            StatusLane(
                status: .todo,
                count: todoCount,
                color: AppStyle.Colors.Status.todo,
                icon: "circle",
                zeroSubtitle: String(localized: "No waiting tasks"),
                countSubtitle: String(localized: "waiting")
            ),
            StatusLane(
                status: .inProgress,
                count: inProgressCount,
                color: inProgressColor,
                icon: inProgressIcon,
                zeroSubtitle: String(localized: "No active tasks"),
                countSubtitle: String(localized: "active")
            ),
            StatusLane(
                status: .done,
                count: doneCount,
                color: AppStyle.Colors.Status.done,
                icon: "checkmark.circle.fill",
                zeroSubtitle: String(localized: "Nothing completed yet"),
                countSubtitle: String(localized: "completed")
            )
        ]
    }

    private var isWIPLimitReached: Bool {
        isFocusGuardEnabled && inProgressCount >= maxActiveTasks
    }

    private var inProgressColor: Color {
        isWIPLimitReached ? AppStyle.Colors.warning : AppStyle.Colors.Status.inProgress
    }

    private var inProgressIcon: String {
        isWIPLimitReached ? "exclamationmark.triangle.fill" : "clock.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.statusRowGap) {
            StatusHeader()

            VStack(spacing: AppStyle.Spacing.none) {
                StatusDistributionBar(
                    todoCount: todoCount,
                    inProgressCount: inProgressCount,
                    doneCount: doneCount,
                    totalCount: totalCount,
                    inProgressColor: inProgressColor
                )
                .padding(.horizontal, AppStyle.Spacing.cardPadding)
                .padding(.top, AppStyle.Spacing.statusCardVerticalPadding)
                .padding(.bottom, AppStyle.Spacing.tight)
                .accessibilityHidden(true)

                ForEach(Array(lanes.enumerated()), id: \.element.status) { index, lane in
                    if index > 0 {
                        dividerLine
                    }

                    StatusRow(
                        lane: lane,
                        isSelected: selectedStatus == lane.status
                    ) {
                        onSelectStatus?(lane.status)
                    }
                }
            }
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(distributionAccessibilityLabel)
        }
    }

    private var dividerLine: some View {
        AppStyle.Colors.divider
            .frame(height: AppStyle.Shapes.dividerHeight)
            .padding(.leading, AppStyle.Spacing.dividerLeading)
    }

    private var distributionAccessibilityLabel: String {
        String(localized: "Status distribution: \(todoCount) to do, \(inProgressCount) in progress, \(doneCount) done")
    }
}

private struct StatusHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tight) {
            Text("Status")
                .sectionHeaderStyle()

            Text("Review tasks by lane")
                .font(AppStyle.Typography.inlineHint)
                .foregroundStyle(AppStyle.Colors.subtleText)
        }
    }
}

private struct StatusDistributionBar: View {
    let todoCount: Int
    let inProgressCount: Int
    let doneCount: Int
    let totalCount: Int
    let inProgressColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppStyle.Colors.track)

                if totalCount > 0 {
                    HStack(spacing: AppStyle.Spacing.none) {
                        segment(count: todoCount, total: totalCount, width: geo.size.width, color: AppStyle.Colors.Status.todo)
                        segment(count: inProgressCount, total: totalCount, width: geo.size.width, color: inProgressColor)
                        segment(count: doneCount, total: totalCount, width: geo.size.width, color: AppStyle.Colors.Status.done)
                    }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: AppStyle.Shapes.statusDistributionBarHeight)
    }

    @ViewBuilder
    private func segment(count: Int, total: Int, width: CGFloat, color: Color) -> some View {
        if count > 0 {
            Rectangle()
                .fill(color)
                .frame(width: width * CGFloat(count) / CGFloat(total))
                .animation(AppStyle.Motion.rowProgress, value: count)
        }
    }
}

private struct StatusRow: View {
    let lane: StatusLane
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: AppStyle.Spacing.statusRowGap) {
                Image(systemName: lane.icon)
                    .font(AppStyle.Typography.iconMedium)
                    .foregroundStyle(lane.color)
                    .frame(width: AppStyle.Shapes.statusRowIconWidth)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppStyle.Spacing.statusRowSubtitleGap) {
                    Text(lane.status.localizedName)
                        .font(AppStyle.Typography.statusRowTitle)
                        .foregroundStyle(AppStyle.Colors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(lane.subtitle)
                        .font(AppStyle.Typography.inlineHint)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppStyle.Spacing.small)

                Circle()
                    .fill(lane.color)
                    .frame(width: AppStyle.Shapes.priorityDotSize, height: AppStyle.Shapes.priorityDotSize)
                    .accessibilityHidden(true)

                Text(lane.count.formatted())
                    .font(AppStyle.Typography.statusRowCount)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .frame(minWidth: AppStyle.Spacing.countFrameWidthComfortable, alignment: .trailing)

                Image(systemName: "chevron.right")
                    .font(AppStyle.Typography.iconSmall)
                    .foregroundStyle(AppStyle.Colors.tertiaryText)
                    .frame(width: AppStyle.Shapes.chevronWidth)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, AppStyle.Spacing.cardPadding)
            .padding(.vertical, AppStyle.Spacing.statusRowVerticalCompact)
            .frame(minHeight: AppStyle.Shapes.minimumTapTarget)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.statusHighlightCornerRadius, style: .continuous)
                        .fill(lane.color.opacity(AppStyle.Opacity.accentWashSelected))
                        .padding(.horizontal, AppStyle.Spacing.statusHighlightPaddingHorizontal)
                        .padding(.vertical, AppStyle.Spacing.statusHighlightPaddingVertical)
                }
            }
            .overlay(alignment: .trailing) {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.statusHighlightCornerRadius, style: .continuous)
                        .stroke(lane.color.opacity(AppStyle.Opacity.accentBorder), lineWidth: AppStyle.Shapes.emphasizedBorderWidth)
                        .padding(.horizontal, AppStyle.Spacing.statusHighlightPaddingHorizontal)
                        .padding(.vertical, AppStyle.Spacing.statusHighlightPaddingVertical)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(lane.status.localizedName), \(lane.count) \(lane.taskWord)"))
        .accessibilityHint("Opens tasks in this lane")
    }
}

private struct StatusLane {
    let status: TaskStatus
    let count: Int
    let color: Color
    let icon: String
    let zeroSubtitle: String
    let countSubtitle: String

    var subtitle: String {
        count == 0 ? zeroSubtitle : String(localized: "\(count.formatted()) \(countSubtitle)")
    }

    var taskWord: String {
        count == 1 ? String(localized: "task") : String(localized: "tasks")
    }
}

private struct StatusPreviewContainer: View {
    let selectedStatus: TaskStatus?
    let todoCount: Int
    let inProgressCount: Int
    let doneCount: Int

    private var totalCount: Int {
        todoCount + inProgressCount + doneCount
    }

    init(selectedStatus: TaskStatus? = nil, todoCount: Int = 2, inProgressCount: Int = 1, doneCount: Int = 1) {
        self.selectedStatus = selectedStatus
        self.todoCount = todoCount
        self.inProgressCount = inProgressCount
        self.doneCount = doneCount
    }

    var body: some View {
        StatusView(
            todoCount: todoCount,
            inProgressCount: inProgressCount,
            doneCount: doneCount,
            totalCount: totalCount,
            maxActiveTasks: 3,
            isFocusGuardEnabled: true,
            selectedStatus: selectedStatus
        )
        .padding(AppStyle.Spacing.outerHorizontal)
        .background(AppStyle.Colors.background)
    }
}

#Preview("Status Default") {
    StatusPreviewContainer()
}

#Preview("Status Empty") {
    StatusPreviewContainer(todoCount: 0, inProgressCount: 0, doneCount: 0)
}

#Preview("Status Selected To Do") {
    StatusPreviewContainer(selectedStatus: .todo)
}

#Preview("Status Selected In Progress") {
    StatusPreviewContainer(selectedStatus: .inProgress)
}

#Preview("Status Selected Done") {
    StatusPreviewContainer(selectedStatus: .done)
}

#Preview("Status Large Dynamic Type") {
    StatusPreviewContainer()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Status Dark Mode") {
    StatusPreviewContainer()
        .preferredColorScheme(.dark)
}
