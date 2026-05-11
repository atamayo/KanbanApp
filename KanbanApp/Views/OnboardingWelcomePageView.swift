import SwiftUI

struct OnboardingWelcomePageView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.regular) {
                    Text("See your work clearly")
                        .font(AppStyle.Typography.heroTitle)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Text("KanbanApp gives you one clear system for your tasks, so you can stop juggling everything in your head and start moving work forward.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                boardPreview

                VStack(spacing: AppStyle.Spacing.regular) {
                    featureRow(
                        icon: "rectangle.3.group.fill",
                        tint: AppStyle.Colors.Status.todo,
                        title: "Visual board",
                        body: "Track work through To Do, In Progress, and Done instead of keeping mental lists."
                    )

                    featureRow(
                        icon: "gauge.with.needle.fill",
                        tint: AppStyle.Colors.Status.inProgress,
                        title: "Actionable dashboard",
                        body: "See progress, WIP pressure, and flow signals that push you toward finishing."
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, AppStyle.Spacing.statusRowGap)
        }
    }

    private var boardPreview: some View {
        HStack(spacing: AppStyle.Spacing.statusRowGap) {
            laneCard(title: "To Do", count: "5", tint: AppStyle.Colors.Status.todo)
            laneCard(title: "In Progress", count: "2", tint: AppStyle.Colors.Status.inProgress)
            laneCard(title: "Done", count: "8", tint: AppStyle.Colors.Status.done)
        }
    }

    private func laneCard(title: String, count: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.compact) {
            Capsule()
                .fill(tint)
                .frame(width: AppStyle.Shapes.lanePreviewAccentWidth, height: AppStyle.Shapes.previewAccentHeight)

            Text(title)
                .font(AppStyle.Typography.statLabel)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Text(count)
                .font(AppStyle.Typography.priorityNumber)
                .foregroundStyle(AppStyle.Colors.primaryText)
        }
        .padding(AppStyle.Spacing.normal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }

    private func featureRow(icon: String, tint: Color, title: String, body: String) -> some View {
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
                Text(title)
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(AppStyle.Colors.primaryText)

                Text(body)
                    .font(AppStyle.Typography.formFooter)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(AppStyle.Spacing.cardContentPadding)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }
}
