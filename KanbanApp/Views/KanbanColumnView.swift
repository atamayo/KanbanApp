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
                .fill(.regularMaterial)
                .shadow(
                    color: AppStyle.Colors.columnShadow,
                    radius: AppStyle.Shapes.columnShadowRadius,
                    y: AppStyle.Shapes.columnShadowY
                )
        )
        .overlay {
            if status == .inProgress && isFocusGuardEnabled && tasks.count >= maxActiveTasks {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.columnCornerRadius)
                    .stroke(AppStyle.Colors.warning.opacity(0.3), lineWidth: 2)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(status.rawValue) column, \(tasks.count) tasks")
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
                            .opacity(phase.isIdentity ? 1 : 0.6)
                            .scaleEffect(phase.isIdentity ? 1 : 0.95)
                    }
            }

            if zoneTasks.isEmpty {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.zoneEmptyCornerRadius)
                    .stroke(priorityZoneColor(priority).opacity(AppStyle.Shapes.zoneEmptyOpacity), style: .init(dash: [AppStyle.Shapes.zoneDashLength]))
                    .frame(height: AppStyle.Shapes.zoneEmptyHeight)
                    .padding(.horizontal, AppStyle.Spacing.zoneContentMargin)
            }

            if priority == .low {
                Color.clear.frame(height: AppStyle.Spacing.emptyBottomSpacer)
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                NotificationCenter.default.post(name: NSNotification.Name("WIPLimitReached"), object: nil)
                return false
            }
            
            droppedID = uuid
            onDrop(uuid, priority)
            return true
        } isTargeted: { targeted in
            withAnimation(.snappy) { targetedZone = targeted ? priority : nil }
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
            Text(priority.rawValue)
                .font(AppStyle.Typography.zoneHeader)
                .foregroundStyle(.secondary)
            Text(count.formatted())
                .font(AppStyle.Typography.zoneCount)
                .foregroundStyle(.tertiary)
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
            Text(status.rawValue)
                .font(AppStyle.Typography.columnHeader)
                .foregroundStyle(.primary)
            Spacer()
            Text(tasks.count.formatted())
                .font(AppStyle.Typography.zoneCount)
                .foregroundStyle(.secondary)
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
