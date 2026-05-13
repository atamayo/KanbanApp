import SwiftUI

struct ProgresView: View {
    let doneCount: Int
    let totalCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var metrics: ProgressMetrics {
        ProgressMetrics(doneCount: doneCount, totalCount: totalCount)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
        .padding(.vertical, AppStyle.Spacing.comfortable)
        .padding(.horizontal, AppStyle.Spacing.heroPadding)
        .cardStyle(cornerRadius: AppStyle.Shapes.headerCornerRadius)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metrics.accessibilityLabel)
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.comfortable) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.statusRowGap) {
                ProgressSummaryText(metrics: metrics)
                ProgressTrack(progress: metrics.progress, reduceMotion: reduceMotion)
            }

            Spacer(minLength: AppStyle.Spacing.none)

            ProgressRing(
                progress: metrics.progress,
                percentageText: metrics.percentageText,
                reduceMotion: reduceMotion
            )
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.comfortable) {
            ProgressSummaryText(metrics: metrics)

            HStack(alignment: .center, spacing: AppStyle.Spacing.comfortable) {
                ProgressTrack(progress: metrics.progress, reduceMotion: reduceMotion)

                Spacer(minLength: AppStyle.Spacing.none)

                ProgressRing(
                    progress: metrics.progress,
                    percentageText: metrics.percentageText,
                    reduceMotion: reduceMotion
                )
            }
        }
    }
}

private struct ProgressSummaryText: View {
    let metrics: ProgressMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tight) {
            Text("Your Progress")
                .font(AppStyle.Typography.inlineHint)
                .foregroundStyle(AppStyle.Colors.subtleText)

            Text(metrics.summaryText)
                .font(AppStyle.Typography.metricSmall)
                .foregroundStyle(AppStyle.Colors.primaryText)
                .contentTransition(.numericText())
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(metrics.insightText)
                .font(AppStyle.Typography.inlineHint)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ProgressTrack: View {
    let progress: Double
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppStyle.Colors.track.opacity(AppStyle.Opacity.subtleTrack))

                if progress > 0 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppStyle.Colors.Status.done.opacity(AppStyle.Opacity.accentForegroundStrong),
                                    AppStyle.Colors.Status.done
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(AppStyle.Shapes.progressMinWidth, geo.size.width * progress))
                        .animation(reduceMotion ? nil : AppStyle.Motion.progress, value: progress)
                }
            }
        }
        .frame(maxWidth: AppStyle.Shapes.progressBarMaxWidth)
        .frame(height: AppStyle.Shapes.progressBarHeight)
        .accessibilityHidden(true)
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
                    lineWidth: AppStyle.Shapes.dashboardRingTrackStroke
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppStyle.Colors.Status.done.opacity(AppStyle.Opacity.accentBorder),
                    style: .init(lineWidth: AppStyle.Shapes.dashboardRingGlowStroke, lineCap: .round)
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
                    style: .init(lineWidth: AppStyle.Shapes.dashboardRingTrackStroke, lineCap: .round)
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
        .frame(width: AppStyle.Shapes.dashboardRingSize, height: AppStyle.Shapes.dashboardRingSize)
        .accessibilityHidden(true)
    }
}

private struct ProgressMetrics {
    let completedCount: Int
    let totalCount: Int
    let progress: Double

    init(doneCount: Int, totalCount: Int) {
        let safeTotalCount = max(totalCount, 0)
        let safeDoneCount = min(max(doneCount, 0), safeTotalCount)

        self.completedCount = safeDoneCount
        self.totalCount = safeTotalCount
        self.progress = safeTotalCount > 0 ? Double(safeDoneCount) / Double(safeTotalCount) : 0
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

        return "\(completedCount.formatted()) of \(totalCount.formatted()) \(taskWord) completed"
    }

    var insightText: String {
        switch percentage {
        case 0 where totalCount == 0:
            return "Add your first task to start tracking progress."
        case 0:
            return "Move your first task to Done to build momentum."
        case 1...39:
            return "Good start, keep moving work toward Done."
        case 40...74:
            return "Momentum is building across your board."
        case 75...99:
            return "Almost there, close the remaining tasks."
        default:
            return "Board complete, all tasks are done."
        }
    }

    var accessibilityLabel: String {
        "Your progress. \(summaryText). \(percentage) percent complete. \(insightText)"
    }

    private var taskWord: String {
        totalCount == 1 ? "task" : "tasks"
    }
}

private struct ProgresPreviewContainer: View {
    let doneCount: Int
    let totalCount: Int

    var body: some View {
        ProgresView(doneCount: doneCount, totalCount: totalCount)
            .padding(AppStyle.Spacing.outerHorizontal)
            .background(AppStyle.Colors.background)
    }
}

#Preview("Progress No Tasks") {
    ProgresPreviewContainer(doneCount: 0, totalCount: 0)
}

#Preview("Progress None Complete") {
    ProgresPreviewContainer(doneCount: 0, totalCount: 4)
}

#Preview("Progress Low") {
    ProgresPreviewContainer(doneCount: 1, totalCount: 4)
}

#Preview("Progress Mid") {
    ProgresPreviewContainer(doneCount: 2, totalCount: 4)
}

#Preview("Progress Almost Complete") {
    ProgresPreviewContainer(doneCount: 3, totalCount: 4)
}

#Preview("Progress Complete") {
    ProgresPreviewContainer(doneCount: 4, totalCount: 4)
}

#Preview("Progress Large Dynamic Type") {
    ProgresPreviewContainer(doneCount: 1, totalCount: 4)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Progress Dark Mode") {
    ProgresPreviewContainer(doneCount: 1, totalCount: 4)
        .preferredColorScheme(.dark)
}
