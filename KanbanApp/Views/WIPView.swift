import SwiftUI

struct WIPView: View {
    let inProgressCount: Int
    let maxActiveTasks: Int
    let isFocusGuardEnabled: Bool
    let blockedInProgressTask: TaskItem?
    let oldestInProgressTask: TaskItem?
    let nextPullTask: TaskItem?
    let onReviewActiveTasks: () -> Void

    private var isWIPLimitReached: Bool {
        isFocusGuardEnabled && inProgressCount >= maxActiveTasks
    }

    private var remainingWIPSlots: Int {
        max(maxActiveTasks - inProgressCount, 0)
    }

    private var wipAccentColor: Color {
        if blockedInProgressTask != nil {
            return AppStyle.Colors.blocked
        }
        if isWIPLimitReached {
            return AppStyle.Colors.warning
        }
        return AppStyle.Colors.Status.inProgress
    }

    private var wipHeadline: String {
        if blockedInProgressTask != nil {
            return "Blocked work needs attention."
        }
        if isWIPLimitReached {
            return "WIP full. Finish before you pull."
        }
        return remainingWIPSlots == 1
            ? "One focus slot left."
            : "Your flow still has room."
    }

    private var wipMessage: String {
        if blockedInProgressTask != nil {
            return "At least one active task is blocked. Unblock flow before pulling more work into motion."
        }

        if isWIPLimitReached {
            return "Your active lane is full. Closing one task now will reduce context switching and free the board to move again."
        }

        if inProgressCount == 0 {
            return "Start deliberately. Pull only the next task you are ready to finish."
        }

        return "Keep active work tight. Protect the remaining capacity so your current tasks can reach done."
    }

    private var spotlightTitle: String {
        if blockedInProgressTask != nil {
            return "Unblock this task first"
        }
        if isWIPLimitReached {
            return "Best task to finish next"
        }
        return "Best task to pull next"
    }

    private var wipIconName: String {
        if blockedInProgressTask != nil {
            return "pause.circle.fill"
        }
        return isWIPLimitReached ? "flame.fill" : "scope"
    }

    private var spotlightTask: TaskItem? {
        if let blockedInProgressTask {
            return blockedInProgressTask
        }
        if isWIPLimitReached {
            return oldestInProgressTask
        }
        return nextPullTask
    }

    private var spotlightSubtitle: String {
        if let blockedInProgressTask {
            return blockedInProgressTask.lastStatusChange.formatted(.relative(presentation: .named))
        }
        if let oldestInProgressTask, isWIPLimitReached {
            return oldestInProgressTask.lastStatusChange.formatted(.relative(presentation: .named))
        }
        if let nextPullTask {
            return "\(nextPullTask.priority.rawValue) priority"
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            Text("WIP Pressure")
                .sectionHeaderStyle()

            VStack(alignment: .leading, spacing: AppStyle.Spacing.comfortable) {
                HStack(alignment: .top, spacing: AppStyle.Spacing.normal) {
                    ZStack {
                        Circle()
                            .fill(wipAccentColor.opacity(AppStyle.Opacity.accentWashSelected))
                            .frame(width: AppStyle.Shapes.iconBadgeLarge, height: AppStyle.Shapes.iconBadgeLarge)

                        Image(systemName: wipIconName)
                            .font(AppStyle.Typography.iconHero)
                            .foregroundStyle(wipAccentColor)
                    }

                    VStack(alignment: .leading, spacing: AppStyle.Spacing.tight) {
                        Text(wipHeadline)
                            .font(AppStyle.Typography.metricMedium)
                            .foregroundStyle(AppStyle.Colors.primaryText)

                        Text(wipMessage)
                            .font(AppStyle.Typography.formFooter)
                            .foregroundStyle(AppStyle.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: AppStyle.Spacing.statusRowGap) {
                    statPill(
                        label: "Active",
                        value: "\(inProgressCount)/\(maxActiveTasks)",
                        tint: wipAccentColor
                    )

                    statPill(
                        label: blockedInProgressTask != nil ? "Priority" : (isWIPLimitReached ? "Action" : "Slots Left"),
                        value: blockedInProgressTask != nil ? "Unblock" : (isWIPLimitReached ? "Finish 1" : "\(remainingWIPSlots)"),
                        tint: blockedInProgressTask != nil ? AppStyle.Colors.blocked : (isWIPLimitReached ? AppStyle.Colors.Status.done : AppStyle.Colors.Status.todo)
                    )
                }

                if let spotlightTask {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                        Text(spotlightTitle)
                            .font(AppStyle.Typography.pillLabel)
                            .foregroundStyle(wipAccentColor)
                            .textCase(.uppercase)

                        Text(spotlightTask.title)
                            .font(AppStyle.Typography.cardTitle)
                            .foregroundStyle(AppStyle.Colors.primaryText)
                            .lineLimit(2)

                        if !spotlightSubtitle.isEmpty {
                            Text(spotlightSubtitle)
                                .font(AppStyle.Typography.cardDate)
                                .foregroundStyle(AppStyle.Colors.secondaryText)
                        }
                    }
                    .padding(AppStyle.Spacing.compactCardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppStyle.Colors.spotlightSurface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                }

                Button(action: onReviewActiveTasks) {
                    HStack {
                        Text(isWIPLimitReached || blockedInProgressTask != nil ? "Review Active Tasks" : "Review Before Pulling")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(AppStyle.Typography.buttonLabel)
                    .foregroundStyle(isWIPLimitReached || blockedInProgressTask != nil ? AppStyle.Colors.inverseText : wipAccentColor)
                    .padding(.horizontal, AppStyle.Spacing.normal)
                    .padding(.vertical, AppStyle.Spacing.regular)
                    .background(
                        isWIPLimitReached || blockedInProgressTask != nil
                        ? AnyShapeStyle(LinearGradient(colors: [wipAccentColor, wipAccentColor.opacity(AppStyle.Opacity.accentForegroundMuted)], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(AppStyle.Colors.spotlightSurface),
                        in: RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(AppStyle.Spacing.heroPadding)
            .accentCardStyle(
                tint: wipAccentColor,
                fillOpacity: isWIPLimitReached ? AppStyle.Opacity.accentFillMuted : AppStyle.Opacity.accentWashStrong
            )
            .shadow(
                color: wipAccentColor.opacity(AppStyle.Opacity.restingShadow),
                radius: AppStyle.Shapes.columnShadowRadius,
                x: AppStyle.Spacing.none,
                y: AppStyle.Spacing.tight
            )
        }
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
}
