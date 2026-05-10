import SwiftUI

struct OnboardingFocusPageView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Protect your focus")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("This app is built around Personal Kanban discipline: do less at once, finish more often, and reduce context switching.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                pressureCard

                VStack(spacing: 14) {
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
            .padding(.bottom, 12)
        }
    }

    private var pressureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("In Progress")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("3 / 3")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppStyle.Colors.warning)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("WIP full")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Finish one task before pulling another.")
                        .font(AppStyle.Typography.cardDate)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppStyle.Colors.track.opacity(0.7))

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
            .frame(height: 10)
        }
        .padding(20)
        .background(AppStyle.Colors.warning.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppStyle.Colors.warning.opacity(0.18), lineWidth: 1)
        )
    }

    private func principleRow(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24)

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
