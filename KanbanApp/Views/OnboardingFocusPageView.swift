import SwiftUI

struct OnboardingFocusPageView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.regular) {
                    Text("Protect your focus")
                        .font(AppStyle.Typography.heroTitle)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Text("This app is built around Personal Kanban discipline: do less at once, finish more often, and reduce context switching.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                pressureCard

                VStack(spacing: AppStyle.Spacing.regular) {
                    principleRow(
                        icon: "line.3.horizontal.decrease.circle.fill",
                        tint: AppStyle.Colors.Status.inProgress,
                        title: "Flow Optimization",
                        body: "Set a max number of active tasks so your attention stays narrow."
                    )

                    principleRow(
                        icon: "flame.fill",
                        tint: AppStyle.Colors.warning,
                        title: "WIP pressure",
                        body: "When your lane is full, the app pushes you back toward finishing before pulling more work."
                    )

                    principleRow(
                        icon: "pause.circle.fill",
                        tint: AppStyle.Colors.Priority.medium,
                        title: "Blocked work stays visible",
                        body: "Waiting work should be seen clearly, not silently mixed into active focus."
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, AppStyle.Spacing.statusRowGap)
        }
    }

    private var pressureCard: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.normal) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.tight) {
                    Text("In Progress")
                        .font(AppStyle.Typography.statLabel)
                        .foregroundStyle(AppStyle.Colors.secondaryText)

                    Text("3 / 3")
                        .font(AppStyle.Typography.metricLarge)
                        .foregroundStyle(AppStyle.Colors.warning)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppStyle.Spacing.tiny) {
                    Text("WIP full")
                        .font(AppStyle.Typography.metricMedium)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Text("Finish one task before pulling another.")
                        .font(AppStyle.Typography.cardDate)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .multilineTextAlignment(.trailing)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppStyle.Colors.track.opacity(AppStyle.Opacity.trackStrong))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppStyle.Colors.Status.inProgress, AppStyle.Colors.warning],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width)
                }
            }
            .frame(height: AppStyle.Shapes.progressBarHeight)
        }
        .padding(AppStyle.Spacing.large)
        .background(AppStyle.Colors.warning.opacity(AppStyle.Opacity.accentWashSubtle), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.primaryControlCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Shapes.primaryControlCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.warning.opacity(AppStyle.Opacity.accentBorderStrong), lineWidth: AppStyle.Shapes.emphasizedBorderWidth)
        )
    }

    private func principleRow(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.regular) {
            Image(systemName: icon)
                .font(AppStyle.Typography.iconMedium)
                .foregroundStyle(tint)
                .frame(width: AppStyle.Spacing.iconFrameWidthMedium)

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
