import SwiftUI

struct WIPView: View {
    let inProgressCount: Int
    let maxActiveTasks: Int
    let isFocusGuardEnabled: Bool
    let oldestInProgressTask: TaskItem?
    let onReviewActiveTasks: () -> Void

    private var isWIPLimitReached: Bool {
        isFocusGuardEnabled && inProgressCount >= maxActiveTasks
    }

    private var remainingWIPSlots: Int {
        max(maxActiveTasks - inProgressCount, 0)
    }

    private var wipAccentColor: Color {
        isWIPLimitReached ? AppStyle.Colors.warning : AppStyle.Colors.Status.inProgress
    }

    private var wipHeadline: String {
        if isWIPLimitReached {
            return "WIP full. Finish before you pull."
        }
        return remainingWIPSlots == 1
            ? "One focus slot left."
            : "Your flow still has room."
    }

    private var wipMessage: String {
        if isWIPLimitReached {
            return "Your active lane is full. Closing one task now will reduce context switching and free the board to move again."
        }

        if inProgressCount == 0 {
            return "Start deliberately. Pull only the next task you are ready to finish."
        }

        return "Keep active work tight. Protect the remaining capacity so your current tasks can reach done."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            Text("WIP Pressure")
                .font(AppStyle.Typography.sectionTitle)
                .foregroundStyle(.secondary)
                .tracking(AppStyle.Typography.sectionTracking)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(wipAccentColor.opacity(0.15))
                            .frame(width: 52, height: 52)

                        Image(systemName: isWIPLimitReached ? "flame.fill" : "scope")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(wipAccentColor)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(wipHeadline)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(wipMessage)
                            .font(AppStyle.Typography.formFooter)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 12) {
                    statPill(
                        label: "Active",
                        value: "\(inProgressCount)/\(maxActiveTasks)",
                        tint: wipAccentColor
                    )

                    statPill(
                        label: isWIPLimitReached ? "Action" : "Slots Left",
                        value: isWIPLimitReached ? "Finish 1" : "\(remainingWIPSlots)",
                        tint: isWIPLimitReached ? AppStyle.Colors.Status.done : AppStyle.Colors.Status.todo
                    )
                }

                if let oldestInProgressTask {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isWIPLimitReached ? "Best task to finish next" : "Keep this one moving")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(wipAccentColor)
                            .textCase(.uppercase)

                        Text(oldestInProgressTask.title)
                            .font(AppStyle.Typography.cardTitle)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(oldestInProgressTask.lastStatusChange, style: .relative)
                            .font(AppStyle.Typography.cardDate)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button(action: onReviewActiveTasks) {
                    HStack {
                        Text(isWIPLimitReached ? "Review Active Tasks" : "Protect Your Focus")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isWIPLimitReached ? Color.white : wipAccentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        isWIPLimitReached
                        ? AnyShapeStyle(LinearGradient(colors: [wipAccentColor, wipAccentColor.opacity(0.72)], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(.white.opacity(0.8)),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .background {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                wipAccentColor.opacity(isWIPLimitReached ? 0.18 : 0.12),
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
                    .stroke(wipAccentColor.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: wipAccentColor.opacity(0.08), radius: 10, x: 0, y: 6)
        }
    }

    private func statPill(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
