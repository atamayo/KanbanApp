import SwiftUI

struct KanbanColumnView: View {
    let tasks: [TaskItem]
    let status: TaskStatus
    let width: CGFloat
    let onDrop: (UUID, TaskPriority) -> Void
    let onSelect: (TaskItem) -> Void
    @State private var droppedID: UUID?
    @State private var targetedZone: TaskPriority?
    
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0

    private var columnColor: Color {
        if status == .inProgress && isFocusGuardEnabled && tasks.count >= maxActiveTasks {
            return AppStyle.Colors.warning
        }
        
        switch status {
        case .todo: return AppStyle.Colors.Status.todo
        case .inProgress: return AppStyle.Colors.Status.inProgress
        case .done: return AppStyle.Colors.Status.done
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.columnContentSpacing) {
            header
            ScrollView {
                VStack(spacing: AppStyle.Spacing.none) {
                    priorityZone(.high)
                    zoneDivider
                    priorityZone(.medium)
                    zoneDivider
                    priorityZone(.low)
                }
                .contentMargins(.horizontal, AppStyle.Spacing.zoneContentMargin, for: .scrollContent)
            }
            .scrollIndicators(.hidden)
        }
        .frame(width: width)
        .padding(AppStyle.Spacing.columnPadding)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.Shapes.columnCornerRadius)
                .fill(AppStyle.Materials.column)
                .shadow(
                    color: AppStyle.Colors.columnShadow,
                    radius: AppStyle.Shapes.columnShadowRadius,
                    y: AppStyle.Shapes.columnShadowY
                )
        )
        .overlay {
            if status == .inProgress && isFocusGuardEnabled && tasks.count >= maxActiveTasks {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.columnCornerRadius)
                    .stroke(AppStyle.Colors.warning.opacity(AppStyle.Opacity.warningBorder), lineWidth: AppStyle.Shapes.warningBorderWidth)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "\(status.localizedName) column, \(tasks.count) tasks"))
        .sensoryFeedback(.success, trigger: droppedID)
    }

    @ViewBuilder
    private func priorityZone(_ priority: TaskPriority) -> some View {
        let zoneTasks = tasks.filter { $0.priority == priority }

        VStack(alignment: .leading, spacing: AppStyle.Spacing.zoneVStackGap) {
            zoneHeader(priority: priority, count: zoneTasks.count)

            ForEach(zoneTasks) { task in
                TaskCardView(task: task, onSelect: onSelect)
                    .onDrag {
                        NSItemProvider(object: task.id.uuidString as NSString)
                    }
                    .scrollTransition(.interactive.threshold(.visible(0.5))) { content, phase in
                        content
                            .opacity(phase.isIdentity ? AppStyle.Opacity.opaque : AppStyle.Opacity.scrollTransition)
                            .scaleEffect(phase.isIdentity ? AppStyle.Opacity.opaque : AppStyle.Opacity.scrollScale)
                    }
            }

            if zoneTasks.isEmpty {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.zoneEmptyCornerRadius)
                    .stroke(priorityZoneColor(priority).opacity(AppStyle.Shapes.zoneEmptyOpacity), style: .init(dash: [AppStyle.Shapes.zoneDashLength]))
                    .frame(height: AppStyle.Shapes.zoneEmptyHeight)
                    .padding(.horizontal, AppStyle.Spacing.zoneContentMargin)
            }

            if priority == .low {
                AppStyle.Colors.clear.frame(height: AppStyle.Spacing.emptyBottomSpacer)
            }
        }
        .frame(minHeight: AppStyle.Shapes.zoneMinHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .background {
            if targetedZone == priority {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.zoneDropCornerRadius)
                    .fill(AppStyle.Colors.Zone.dropHighlight)
            }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let id = items.first, let uuid = UUID(uuidString: id)
            else { return false }
            
            if status == .inProgress && isFocusGuardEnabled && tasks.count >= maxActiveTasks {
                wipLimitHitCount += 1
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                NotificationCenter.default.post(name: NSNotification.Name("WIPLimitReached"), object: nil)
                return false
            }
            
            droppedID = uuid
            onDrop(uuid, priority)
            return true
        } isTargeted: { targeted in
            withAnimation(AppStyle.Motion.snappy) { targetedZone = targeted ? priority : nil }
        }
    }

    private var zoneDivider: some View {
        Rectangle()
            .fill(AppStyle.Colors.zoneDivider)
            .frame(height: AppStyle.Shapes.dividerHeight)
            .padding(.vertical, AppStyle.Spacing.zonePaddingVertical)
    }

    private func zoneHeader(priority: TaskPriority, count: Int) -> some View {
        HStack(spacing: AppStyle.Spacing.zoneHStackGap) {
            Image(systemName: priorityIconName(priority))
                .foregroundStyle(priorityZoneColor(priority))
                .font(AppStyle.Typography.zoneIcon)
            Text(priority.localizedName)
                .font(AppStyle.Typography.zoneHeader)
                .foregroundStyle(AppStyle.Colors.secondaryText)
            Text(count.formatted())
                .font(AppStyle.Typography.zoneCount)
                .foregroundStyle(AppStyle.Colors.tertiaryText)
            Spacer()
        }
        .padding(.horizontal, AppStyle.Spacing.zoneContentMargin)
        .padding(.top, AppStyle.Spacing.zoneContentMargin)
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(columnColor)
                .frame(width: AppStyle.Shapes.dotSize, height: AppStyle.Shapes.dotSize)
            Text(status.localizedName)
                .font(AppStyle.Typography.columnHeader)
                .foregroundStyle(AppStyle.Colors.primaryText)
            Spacer()
            Text(tasks.count.formatted())
                .font(AppStyle.Typography.zoneCount)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .padding(.horizontal, AppStyle.Spacing.badgeHorizontalPadding)
                .padding(.vertical, AppStyle.Spacing.badgeVerticalPadding)
                .background(AppStyle.Colors.badgeBackground, in: .capsule)
                .contentTransition(.numericText())
        }
    }

    private func priorityZoneColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return AppStyle.Colors.Zone.high
        case .medium: return AppStyle.Colors.Zone.medium
        case .low: return AppStyle.Colors.Zone.low
        }
    }

    private func priorityIconName(_ priority: TaskPriority) -> String {
        switch priority {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }
}
