import SwiftUI

struct WIPView: View {
    let allTasks: [TaskItem]
    let maxActiveTasks: Int
    let isFocusGuardEnabled: Bool
    let onOpenCoach: () -> Void

    private var recommendation: WIPCoachRecommendation {
        WIPCoachEngine.evaluate(
            tasks: allTasks,
            maxActiveTasks: maxActiveTasks,
            isFocusGuardEnabled: isFocusGuardEnabled
        )
    }

    private var wipAccentColor: Color {
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
        Button(action: onOpenCoach) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.normal) {
                header
                stats
            }
            .padding(AppStyle.Spacing.heroPadding)
            .accentCardStyle(
                tint: wipAccentColor,
                fillOpacity: AppStyle.Opacity.accentWashStrong
            )
            .shadow(
                color: wipAccentColor.opacity(AppStyle.Opacity.restingShadow),
                radius: AppStyle.Shapes.columnShadowRadius,
                x: AppStyle.Spacing.none,
                y: AppStyle.Spacing.tight
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilitySummary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.normal) {
            HStack(alignment: .center, spacing: AppStyle.Spacing.regular) {
                ZStack {
                    Circle()
                        .fill(wipAccentColor.opacity(AppStyle.Opacity.accentWashSelected))
                        .frame(width: AppStyle.Shapes.iconBadgeSmall, height: AppStyle.Shapes.iconBadgeSmall)

                    Image(systemName: wipIconName)
                        .font(AppStyle.Typography.iconMedium)
                        .foregroundStyle(wipAccentColor)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                    Text("Coach")
                        .font(AppStyle.Typography.statusLabelHighlighted)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Text(recommendation.label)
                        .font(AppStyle.Typography.cardDate)
                        .foregroundStyle(wipAccentColor)
                        .textCase(.uppercase)
                }
            }

            Spacer(minLength: AppStyle.Spacing.none)

            Image(systemName: "arrow.right")
                .font(AppStyle.Typography.iconSmall)
                .foregroundStyle(AppStyle.Colors.tertiaryText)
                .accessibilityHidden(true)
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            Text(recommendation.headline)
                .font(AppStyle.Typography.formFooter)
                .foregroundStyle(AppStyle.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

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
    }

    private var accessibilitySummary: String {
        let taskSummary = recommendation.recommendedTask.map { String(localized: "Recommended task: \($0.title).") } ?? String(localized: "No recommended task.")
        return String(localized: "Work in progress pressure. \(recommendation.headline) \(recommendation.stats.activeCount) of \(recommendation.stats.wipLimit) tasks active. \(recommendation.stats.slotsLeft) slots left. \(recommendation.label.capitalized). \(taskSummary)")
    }

    private func statPill(label: LocalizedStringKey, value: String, tint: Color) -> some View {
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

#Preview("WIP Has Room") {
    WIPView(
        allTasks: WIPPreviewData.hasRoom,
        maxActiveTasks: 3,
        isFocusGuardEnabled: true,
        onOpenCoach: {}
    )
    .padding()
    .background(AppStyle.Colors.background)
}

#Preview("WIP At Limit") {
    WIPView(
        allTasks: WIPPreviewData.atLimit,
        maxActiveTasks: 3,
        isFocusGuardEnabled: true,
        onOpenCoach: {}
    )
    .padding()
    .background(AppStyle.Colors.background)
}

#Preview("WIP Blocked") {
    WIPView(
        allTasks: WIPPreviewData.blocked,
        maxActiveTasks: 3,
        isFocusGuardEnabled: true,
        onOpenCoach: {}
    )
    .padding()
    .background(AppStyle.Colors.background)
}

#Preview("WIP Overloaded Large Type") {
    WIPView(
        allTasks: WIPPreviewData.overloaded,
        maxActiveTasks: 3,
        isFocusGuardEnabled: true,
        onOpenCoach: {}
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
        onOpenCoach: {}
    )
    .padding()
    .background(AppStyle.Colors.background)
    .preferredColorScheme(.dark)
}

enum WIPPreviewData {
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
