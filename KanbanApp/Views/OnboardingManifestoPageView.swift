import SwiftUI

struct OnboardingManifestoPageView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Personal Kanban in practice")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("The manifesto is simple: visualize your work, limit work in progress, pull only when there is room, and let Done stay visible.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    principlePill("Visualize", tint: AppStyle.Colors.Status.todo)
                    principlePill("Limit WIP", tint: AppStyle.Colors.Status.inProgress)
                    principlePill("Finish", tint: AppStyle.Colors.Status.done)
                }

                VStack(spacing: 14) {
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
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
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

    private func manifestoRow(icon: String, tint: Color, title: String, body: String) -> some View {
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
