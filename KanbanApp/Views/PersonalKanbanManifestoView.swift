import SwiftUI

struct PersonalKanbanManifestoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                heroCard
                principlesSection
                implementationSection
                benefitsSection
            }
            .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
            .padding(.vertical, AppStyle.Spacing.outerVertical)
        }
        .background(AppStyle.Colors.background)
        .navigationTitle("Manifesto")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.regular) {
            Text("Personal Kanban")
                .font(AppStyle.Typography.manifestoTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)

            Text("This app applies Personal Kanban by helping you see your work clearly, protect your focus, and finish before starting more.")
                .font(AppStyle.Typography.formFooter)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                principlePill("Visualize work", tint: AppStyle.Colors.Status.todo)
                principlePill("Limit WIP", tint: AppStyle.Colors.Status.inProgress)
                principlePill("Finish", tint: AppStyle.Colors.Status.done)
            }
        }
        .padding(AppStyle.Spacing.heroPadding)
        .accentCardStyle(tint: AppStyle.Colors.Status.todo)
    }

    private var principlesSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("How This App Supports It")

            VStack(spacing: AppStyle.Spacing.regular) {
                manifestoCard(
                    icon: "rectangle.3.group.fill",
                    title: "Your work is visible",
                    body: "The board makes every task explicit through To Do, In Progress, and Done, so you can see what is waiting, what is active, and what has been completed."
                )

                manifestoCard(
                    icon: "line.3.horizontal.decrease.circle.fill",
                    title: "Flow Optimization protects focus",
                    body: "The app can enforce a WIP limit so too many tasks do not enter In Progress at once. That keeps attention narrow and reduces context switching."
                )

                manifestoCard(
                    icon: "checkmark.circle.fill",
                    title: "Done stays visible",
                    body: "Completion is not hidden. The dashboard and board both make finished work visible so progress feels concrete and motivating."
                )

                manifestoCard(
                    icon: "flame.fill",
                    title: "Pressure appears at the right moment",
                    body: "When your active lane is full, the dashboard pushes you back toward finishing. The app encourages pull, not overload."
                )
            }
        }
    }

    private var implementationSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("How To Use This App")

            VStack(spacing: AppStyle.Spacing.regular) {
                manifestoCard(
                    icon: "square.grid.3x3.fill",
                    title: "Work from the board",
                    body: "Keep tasks moving through the three core states. The board is the main picture of your flow, not just a list of tasks."
                )

                manifestoCard(
                    icon: "arrow.down.circle.fill",
                    title: "Pull only when you have room",
                    body: "Move a task into In Progress only when capacity opens up. Let completion create space for the next commitment."
                )

                manifestoCard(
                    icon: "chart.bar.fill",
                    title: "Use the dashboard to rebalance flow",
                    body: "The dashboard shows progress, WIP pressure, and priority distribution so you can decide whether to finish, pause, or avoid pulling more."
                )
            }
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("What The User Gains")

            VStack(spacing: AppStyle.Spacing.regular) {
                manifestoCard(
                    icon: "brain.fill",
                    title: "Lower mental load",
                    body: "Tasks no longer have to live in memory. The board and dashboard hold the system for you."
                )

                manifestoCard(
                    icon: "scope",
                    title: "Stronger focus",
                    body: "A limited In Progress lane makes it easier to stay with the current work instead of scattering effort across too many tasks."
                )

                manifestoCard(
                    icon: "speedometer",
                    title: "Clearer decisions",
                    body: "Priority signals, WIP guidance, and visible task states help the user choose what to finish next with less friction."
                )

                manifestoCard(
                    icon: "sparkles",
                    title: "More motivation to finish",
                    body: "Visible progress and a real Done state turn completion into something you can see, not just something you intend."
                )
            }
        }
    }

    private func principlePill(_ title: LocalizedStringKey, tint: Color) -> some View {
        Text(title)
            .font(AppStyle.Typography.pillLabel)
            .foregroundStyle(tint)
            .padding(.horizontal, AppStyle.Spacing.emphasizedPillHorizontalPadding)
            .padding(.vertical, AppStyle.Spacing.emphasizedPillVerticalPadding)
            .background(tint.opacity(AppStyle.Opacity.accentWashStrong), in: Capsule())
    }

    private func manifestoCard(icon: String, title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.regular) {
            ZStack {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                    .fill(AppStyle.Colors.surface)
                    .frame(width: AppStyle.Shapes.iconBadgeSmall, height: AppStyle.Shapes.iconBadgeSmall)

                Image(systemName: icon)
                    .font(AppStyle.Typography.iconMedium)
                    .foregroundStyle(AppStyle.Colors.Status.todo)
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

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .sectionHeaderStyle()
    }
}
