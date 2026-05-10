import SwiftUI

struct OnboardingWelcomePageView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("See your work clearly")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("KanbanApp gives you one clear system for your tasks, so you can stop juggling everything in your head and start moving work forward.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                boardPreview

                VStack(spacing: 14) {
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
            .padding(.bottom, 12)
        }
    }

    private var boardPreview: some View {
        HStack(spacing: 12) {
            laneCard(title: "To Do", count: "5", tint: AppStyle.Colors.Status.todo)
            laneCard(title: "In Progress", count: "2", tint: AppStyle.Colors.Status.inProgress)
            laneCard(title: "Done", count: "8", tint: AppStyle.Colors.Status.done)
        }
    }

    private func laneCard(title: String, count: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(tint)
                .frame(width: 32, height: 6)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(count)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 16)
    }

    private func featureRow(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
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
}
