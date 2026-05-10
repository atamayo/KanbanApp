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
        VStack(alignment: .leading, spacing: 14) {
            Text("Personal Kanban")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("This app applies Personal Kanban by helping you see your work clearly, protect your focus, and finish before starting more.")
                .font(AppStyle.Typography.formFooter)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                principlePill("Visualize work", tint: AppStyle.Colors.Status.todo)
                principlePill("Limit WIP", tint: AppStyle.Colors.Status.inProgress)
                principlePill("Finish", tint: AppStyle.Colors.Status.done)
            }
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppStyle.Colors.Status.todo.opacity(0.14),
                            AppStyle.Colors.surface,
                            AppStyle.Colors.surface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: 1)
        }
    }

    private var principlesSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("How This App Supports It")

            VStack(spacing: 14) {
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

            VStack(spacing: 14) {
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

            VStack(spacing: 14) {
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

    private func principlePill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(AppStyle.Typography.pillLabel)
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private func manifestoCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppStyle.Colors.surface)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.Status.todo)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(.primary)

                Text(body)
                    .font(AppStyle.Typography.formFooter)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(18)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppStyle.Typography.sectionTitle)
            .foregroundStyle(.secondary)
            .tracking(AppStyle.Typography.sectionTracking)
    }
}
