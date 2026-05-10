import SwiftUI
import SwiftData

struct TaskCardView: View {
    private enum FlowState {
        case ready
        case fresh
        case active
        case aging
        case stalled
        case completed

        var label: String {
            switch self {
            case .ready: return "Ready"
            case .fresh: return "Fresh"
            case .active: return "Active"
            case .aging: return "Aging"
            case .stalled: return "Stalled"
            case .completed: return "Closed"
            }
        }

        var icon: String {
            switch self {
            case .ready: return "play.circle"
            case .fresh: return "sparkles"
            case .active: return "bolt.circle"
            case .aging: return "clock.badge.exclamationmark"
            case .stalled: return "exclamationmark.circle"
            case .completed: return "checkmark.seal"
            }
        }
    }

    let task: TaskItem
    let onSelect: (TaskItem) -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var lastMovedStatus: TaskStatus?
    @State private var isDragging = false
    @State private var wipLimitError = false
    @State private var showingWIPLimitAlert = false
    
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = false
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @Query(filter: #Predicate<TaskItem> { $0.statusRaw == "In Progress" }) private var inProgressTasks: [TaskItem]

    private var statusColor: Color {
        switch task.status {
        case .todo: return AppStyle.Colors.Status.todo
        case .inProgress: return AppStyle.Colors.Status.inProgress
        case .done: return AppStyle.Colors.Status.done
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return AppStyle.Colors.Priority.high
        case .medium: return AppStyle.Colors.Priority.medium
        case .low: return AppStyle.Colors.Priority.low
        }
    }

    private var closedAt: Date? {
        guard task.status == .done else { return nil }
        return task.finalizedAt ?? task.updatedAt
    }

    private var flowReferenceDate: Date {
        switch task.status {
        case .todo:
            return task.createdAt
        case .inProgress:
            return task.lastStatusChange
        case .done:
            return closedAt ?? task.updatedAt
        }
    }

    private var flowAge: TimeInterval {
        Date().timeIntervalSince(flowReferenceDate)
    }

    private var flowState: FlowState {
        switch task.status {
        case .todo:
            return .ready
        case .done:
            return .completed
        case .inProgress:
            if flowAge < 24 * 60 * 60 {
                return .fresh
            } else if flowAge < 3 * 24 * 60 * 60 {
                return .active
            } else if flowAge < 5 * 24 * 60 * 60 {
                return .aging
            } else {
                return .stalled
            }
        }
    }

    private var flowColor: Color {
        switch flowState {
        case .ready:
            return AppStyle.Colors.Status.todo
        case .fresh:
            return .secondary
        case .active:
            return AppStyle.Colors.Status.done
        case .aging:
            return AppStyle.Colors.Priority.medium
        case .stalled:
            return AppStyle.Colors.Priority.high
        case .completed:
            return AppStyle.Colors.Status.done
        }
    }

    private var flowDurationText: String {
        let minutes = Int(flowAge / 60)
        let hours = Int(flowAge / 3600)
        let days = Int(flowAge / 86400)

        if days > 0 { return "\(days)d" }
        if hours > 0 { return "\(hours)h" }
        if minutes > 0 { return "\(minutes)m" }
        return "now"
    }

    private var accentWidthRatio: CGFloat {
        switch flowState {
        case .ready: return 0.18
        case .fresh: return 0.28
        case .active: return 0.52
        case .aging: return 0.76
        case .stalled: return 1.0
        case .completed: return 0.42
        }
    }

    var body: some View {
        mainContent
            .padding(AppStyle.Spacing.cardPadding)
            .background(cardBackground)
            .scaleEffect(isDragging ? AppStyle.Shapes.dragScale : 1.0)
            .draggable(task.id.uuidString) {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
                    .fill(AppStyle.Colors.surface)
                    .frame(width: AppStyle.Shapes.columnMinWidth, height: AppStyle.Shapes.zoneMinHeight)
                    .onAppear { isDragging = true }
                    .onDisappear { isDragging = false }
            }
            .onTapGesture { onSelect(task) }
            .contextMenu { contextMenuItems }
            .hoverEffect(.lift)
            .sensoryFeedback(.impact(weight: .light), trigger: lastMovedStatus)
            .sensoryFeedback(.error, trigger: wipLimitError)
            .overlay(alignment: .top) {
                if wipLimitError {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
                        .stroke(AppStyle.Colors.warning, lineWidth: 2)
                    .animation(.spring(), value: wipLimitError)
                }
            }
            .accessibilityLabel(task.title)
            .accessibilityHint(task.status.rawValue)
            .customAlert(
                isPresented: $showingWIPLimitAlert,
                iconName: "brain.head.profile",
                title: "WIP Limit Reached",
                message: "Personal Kanban recommends a WIP limit of 2 or 3 to minimize context-switching and finish tasks faster. Finish or move an active task before moving another task into In Progress."
            )
    }

    private var mainContent: some View {
        HStack(spacing: AppStyle.Spacing.medium) {
            checkbox
            taskDetails
            dragHandle
        }
    }

    private var checkbox: some View {
        Button {
            withAnimation(.spring) {
                toggleCompletion()
            }
        } label: {
            Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: AppStyle.Spacing.checkboxSize))
                .foregroundStyle(task.status == .done ? AppStyle.Colors.Status.done : .secondary)
        }
        .buttonStyle(.plain)
    }

    private var taskDetails: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            HStack(alignment: .top) {
                Text(task.title)
                    .font(AppStyle.Typography.cardTitle)
                    .lineLimit(2)
                    .foregroundStyle(task.status == .done ? .secondary : .primary)
                    .strikethrough(task.status == .done)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppStyle.Spacing.tiny) {
                    priorityPill
                }
            }

            if !task.desc.isEmpty {
                Text(task.desc)
                    .font(AppStyle.Typography.cardDescription)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            timeInfo
        }
    }

    private var timeInfo: some View {
        HStack(spacing: AppStyle.Spacing.tiny) {
            Image(systemName: flowState.icon)
            Text(flowState.label)
            Text("·")
            Text(flowDurationText)
        }
        .font(AppStyle.Typography.cardDate)
        .foregroundStyle(flowColor)
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: AppStyle.Shapes.iconSizeMedium, weight: .semibold))
            .foregroundStyle(.quaternary)
            .frame(width: AppStyle.Spacing.dragHandleWidth)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
            .fill(AppStyle.Colors.surface)
            .overlay(alignment: .bottomLeading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [flowColor.opacity(0.95), flowColor.opacity(0.45)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(28, geo.size.width * accentWidthRatio), height: 4)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }
                .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
                    .stroke(flowColor.opacity(0.08), lineWidth: 1)
            }
            .shadow(
                color: flowColor.opacity(isDragging ? 0.18 : 0.08),
                radius: isDragging ? AppStyle.Shapes.dragShadowRadius : AppStyle.Shapes.tinyShadowRadius,
                y: isDragging ? AppStyle.Shapes.dragShadowRadius / 2 : AppStyle.Shapes.tinyShadowY
            )
    }

    private var priorityPill: some View {
        Text(task.priority.rawValue)
            .font(AppStyle.Typography.pillLabel)
            .padding(.horizontal, AppStyle.Spacing.pillHorizontalPadding)
            .padding(.vertical, AppStyle.Spacing.pillVerticalPadding)
            .background(priorityColor.opacity(0.12))
            .foregroundStyle(priorityColor)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Menu {
            ForEach(TaskPriority.allCases) { p in
                Button {
                    task.priority = p
                    try? modelContext.save()
                } label: {
                    Label(p.rawValue, systemImage: priorityIconName(p))
                }
            }
        } label: {
            Label("Priority", systemImage: "flag")
        }
        Divider()
        if task.status != .todo {
            Button {
                move(.todo)
                lastMovedStatus = .todo
            } label: {
                Label("Move to To Do", systemImage: "arrow.left")
            }
        }
        if task.status != .inProgress {
            Button {
                move(.inProgress)
                lastMovedStatus = .inProgress
            } label: {
                Label("Move to In Progress", systemImage: "arrow.right")
            }
        }
        if task.status != .done {
            Button {
                move(.done)
                lastMovedStatus = .done
            } label: {
                Label("Mark Done", systemImage: "checkmark")
            }
        }
        Divider()
        Button(role: .destructive) {
            withAnimation { delete() }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func move(_ status: TaskStatus) {
        if status == .inProgress && isFocusGuardEnabled && inProgressTasks.count >= maxActiveTasks {
            triggerLimitFeedback()
            return
        }
        
        task.status = status
        task.updatedAt = Date()
        try? modelContext.save()
    }

    private func toggleCompletion() {
        let newStatus: TaskStatus = task.status == .done ? .todo : .done
        
        if newStatus == .inProgress && isFocusGuardEnabled && inProgressTasks.count >= maxActiveTasks {
            triggerLimitFeedback()
            return
        }

        task.status = newStatus
        task.updatedAt = Date()
        try? modelContext.save()
    }

    private func triggerLimitFeedback() {
        withAnimation(.spring()) {
            wipLimitError = true
        }
        showingWIPLimitAlert = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.spring()) {
                wipLimitError = false
            }
        }
    }

    private func delete() {
        modelContext.delete(task)
        try? modelContext.save()
    }

    private func priorityIconName(_ priority: TaskPriority) -> String {
        switch priority {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }
}
