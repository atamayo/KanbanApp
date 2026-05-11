import SwiftUI

struct OnboardingManifestoPageView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.regular) {
                    Text("Personal Kanban in practice")
                        .font(AppStyle.Typography.heroTitle)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Text("The manifesto is simple: visualize your work, limit work in progress, pull only when there is room, and let Done stay visible.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: AppStyle.Spacing.compact) {
                    principlePill("Visualize", tint: AppStyle.Colors.Status.todo)
                    principlePill("Limit WIP", tint: AppStyle.Colors.Status.inProgress)
                    principlePill("Finish", tint: AppStyle.Colors.Status.done)
                }

                VStack(spacing: AppStyle.Spacing.regular) {
                    manifestoRow(
                        icon: "eye.fill",
                        tint: AppStyle.Colors.Status.todo,
                        title: "Visualize your work",
                        body: "The board makes your commitments visible so nothing important stays vague or hidden."
                    )

                    manifestoRow(
                        icon: "arrow.down.circle.fill",
                        tint: AppStyle.Colors.Status.inProgress,
                        title: "Pull instead of overload",
                        body: "Start a new task only when capacity opens. Completion creates space for the next commitment."
                    )

                    manifestoRow(
                        icon: "checkmark.circle.fill",
                        tint: AppStyle.Colors.Status.done,
                        title: "Let Done motivate you",
                        body: "Finished work is part of the system. Seeing tasks close gives momentum and reduces stress."
                    )
                }

                Text("Use the board to choose deliberately, the dashboard to protect flow, and the Done column to keep momentum real.")
                    .font(AppStyle.Typography.guidanceFooter)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, AppStyle.Spacing.statusRowGap)
        }
    }

    private func principlePill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(AppStyle.Typography.pillLabel)
            .foregroundStyle(tint)
            .padding(.horizontal, AppStyle.Spacing.emphasizedPillHorizontalPadding)
            .padding(.vertical, AppStyle.Spacing.emphasizedPillVerticalPadding)
            .background(tint.opacity(AppStyle.Opacity.accentWashStrong), in: Capsule())
    }

    private func manifestoRow(icon: String, tint: Color, title: String, body: String) -> some View {
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
