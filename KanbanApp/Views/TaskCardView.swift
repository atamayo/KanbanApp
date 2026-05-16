import SwiftUI
import SwiftData

struct TaskCardView: View {
    enum SwipeConfiguration {
        case disabled
        case listStatusActions
    }

    private enum FlowState {
        case ready
        case blocked
        case fresh
        case active
        case aging
        case stalled
        case completed

        var label: String {
            switch self {
            case .ready: return "Ready"
            case .blocked: return "Blocked"
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
            case .blocked: return "pause.circle.fill"
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
    let swipeConfiguration: SwipeConfiguration
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastMovedStatus: TaskStatus?
    @State private var isDragging = false
    @State private var wipLimitError = false
    @State private var showingWIPLimitAlert = false
    
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0
    @AppStorage("taskAgingNotificationDayThreshold") private var taskAgingNotificationDayThreshold = 3
    @AppStorage("taskStalledNotificationDayThreshold") private var taskStalledNotificationDayThreshold = 5
    @Query(filter: #Predicate<TaskItem> { $0.statusRaw == "In Progress" }) private var inProgressTasks: [TaskItem]

    init(
        task: TaskItem,
        onSelect: @escaping (TaskItem) -> Void,
        swipeConfiguration: SwipeConfiguration = .disabled
    ) {
        self.task = task
        self.onSelect = onSelect
        self.swipeConfiguration = swipeConfiguration
    }

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

    private var metadataTint: Color {
        task.isBlocked ? AppStyle.Colors.blocked : flowColor
    }

    private var flowReferenceDate: Date {
        switch task.status {
        case .todo:
            return task.createdAt
        case .inProgress:
            return TaskAgingEvaluator.activeSince(for: task)
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
            if task.isBlocked {
                return .blocked
            }
            if flowAge < 24 * 60 * 60 {
                return .fresh
            } else if flowAge < TimeInterval(taskAgingNotificationDayThreshold * 86_400) {
                return .active
            } else if flowAge < TimeInterval(max(taskStalledNotificationDayThreshold, taskAgingNotificationDayThreshold + 1) * 86_400) {
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
        case .blocked:
            return AppStyle.Colors.blocked
        case .fresh:
            return AppStyle.Colors.Status.inProgress
        case .active:
            return AppStyle.Colors.Status.inProgress
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

    private var statusIconName: String {
        if task.isArchived {
            return "archivebox.fill"
        }

        switch task.status {
        case .todo:
            return "circle.fill"
        case .inProgress:
            return task.isBlocked ? "pause.circle.fill" : "play.circle.fill"
        case .done:
            return "checkmark.circle.fill"
        }
    }

    private var statusBadgeText: String {
        if task.isArchived {
            return "Archived"
        }
        return task.status == .todo ? flowState.label : task.status.rawValue
    }

    private var statusBadgeIcon: String {
        task.status == .todo ? flowState.icon : statusIconName
    }

    private var statusBadgeTint: Color {
        task.isBlocked ? AppStyle.Colors.blocked : statusColor
    }

    private var priorityIconName: String {
        priorityIconName(task.priority)
    }

    private var metadataSummary: String {
        if task.isArchived, let archivedAt = task.archivedAt {
            let archivedAge = Date().timeIntervalSince(archivedAt)
            let minutes = Int(archivedAge / 60)
            let hours = Int(archivedAge / 3600)
            let days = Int(archivedAge / 86400)
            let duration: String

            if days > 0 {
                duration = "\(days)d"
            } else if hours > 0 {
                duration = "\(hours)h"
            } else if minutes > 0 {
                duration = "\(minutes)m"
            } else {
                duration = "now"
            }

            return "Archived \(duration) ago"
        }

        switch task.status {
        case .todo:
            return "\(flowState.label), created \(flowDurationText) ago"
        case .inProgress:
            return "\(flowState.label), in progress for \(flowDurationText)"
        case .done:
            return "Closed \(flowDurationText) ago"
        }
    }

    private var accessibilitySummary: String {
        var parts = [
            task.title,
            task.status.rawValue,
            "\(task.priority.rawValue) priority",
            metadataSummary
        ]

        if task.isBlocked {
            parts.append("Blocked")
        }

        if task.status == .done {
            parts.append("Completed")
        }

        if task.isArchived {
            parts.append("Archived")
        }

        return parts.joined(separator: ", ")
    }

    private var accessibilityHintText: String {
        "Double-tap to open details. Swipe or long press for actions. Drag the card to reorder."
    }

    var body: some View {
        Button {
            onSelect(task)
        } label: {
            mainContent
                .padding(AppStyle.Spacing.cardContentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .background(cardBackground)
        .scaleEffect(isDragging && !reduceMotion ? AppStyle.Shapes.dragScale : 1.0)
        .contentShape(Rectangle())
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous))
            .draggable(task.id.uuidString) {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
                    .fill(AppStyle.Colors.surface)
                    .frame(width: AppStyle.Shapes.columnMinWidth, height: AppStyle.Shapes.zoneMinHeight)
                    .onAppear { isDragging = true }
                    .onDisappear { isDragging = false }
            }
            .contextMenu { contextMenuItems }
            .hoverEffect(.lift)
            .sensoryFeedback(.impact(weight: .light), trigger: lastMovedStatus)
            .sensoryFeedback(.error, trigger: wipLimitError)
            .overlay(alignment: .top) {
                if wipLimitError {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
                        .stroke(AppStyle.Colors.warning, lineWidth: AppStyle.Shapes.warningBorderWidth)
                    .animation(AppStyle.Motion.standardSpring, value: wipLimitError)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            .accessibilityHint(accessibilityHintText)
            .customAlert(
                isPresented: $showingWIPLimitAlert,
                iconName: "brain.head.profile",
                title: "WIP Limit Reached",
                message: "Personal Kanban recommends a WIP limit of 2 or 3 to minimize context-switching and finish tasks faster. Finish or move an active task before moving another task into In Progress."
            )
            .taskCardSwipeActions(configuration: swipeConfiguration, task: task) { status in
                performStatusTransition(to: status)
            } onArchive: {
                archiveTask()
            } onRestore: {
                restoreTask()
            }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            taskHeader
            taskDescription
            taskMetadataRow
        }
    }

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            taskTitle
            badgeGroup
        }
    }

    private var taskTitle: some View {
        Text(task.title)
            .font(AppStyle.Typography.detailTitle)
            .foregroundStyle(task.status == .done ? AppStyle.Colors.secondaryText : AppStyle.Colors.primaryText)
            .strikethrough(task.status == .done, color: AppStyle.Colors.Status.done.opacity(AppStyle.Opacity.accentForegroundMuted))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var badgeGroup: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppStyle.Spacing.tiny) {
                taskBadges
            }

            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                taskBadges
            }
        }
    }

    @ViewBuilder
    private var taskBadges: some View {
        if task.isBlocked {
            blockedPill
        }

        TaskBadge(
            text: statusBadgeText,
            systemImage: statusBadgeIcon,
            tint: statusBadgeTint
        )

        priorityPill
    }

    @ViewBuilder
    private var taskDescription: some View {
        if !task.desc.isEmpty {
            Text(task.desc)
                .font(AppStyle.Typography.formFooter)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var taskMetadataRow: some View {
        metadataItem(icon: flowState.icon, text: metadataSummary, tint: metadataTint)
        .font(AppStyle.Typography.inlineHint)
        .foregroundStyle(AppStyle.Colors.subtleText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardBackground: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                .fill(AppStyle.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                        .fill(AppStyle.Colors.cardSheen)
                )

            Rectangle()
                .fill(metadataTint)
                .frame(width: AppStyle.Shapes.sideBarWidth)
                .accessibilityHidden(true)
        }
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                    .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
            )
            .shadow(
                color: AppStyle.Colors.cardShadow,
                radius: AppStyle.Shapes.cardShadowRadius,
                x: AppStyle.Shapes.cardShadowX,
                y: AppStyle.Shapes.cardShadowY
            )
    }

    private func metadataItem(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: AppStyle.Spacing.tiny) {
            Image(systemName: icon)
                .foregroundStyle(tint)

            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    private var priorityPill: some View {
        TaskBadge(
            text: task.priority.rawValue,
            systemImage: priorityIconName,
            tint: priorityColor
        )
    }

    private var blockedPill: some View {
        TaskBadge(
            text: "Blocked",
            systemImage: "pause.circle.fill",
            tint: AppStyle.Colors.blocked
        )
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
        if task.status == .inProgress {
            Button {
                task.isBlocked.toggle()
                task.updatedAt = Date()
                try? modelContext.save()
            } label: {
                Label(
                    task.isBlocked ? "Mark Active" : "Mark Blocked / Waiting",
                    systemImage: task.isBlocked ? "play.circle.fill" : "pause.circle.fill"
                )
            }
            Divider()
        }
        Divider()
        if task.status != .todo {
            Button {
                performStatusTransition(to: .todo)
            } label: {
                Label("Move to To Do", systemImage: "arrow.left")
            }
        }
        if task.status != .inProgress {
            Button {
                performStatusTransition(to: .inProgress)
            } label: {
                Label("Move to In Progress", systemImage: task.status == .done ? "arrow.left" : "arrow.right")
            }
        }
        if task.status != .done {
            Button {
                performStatusTransition(to: .done)
            } label: {
                Label("Mark Done", systemImage: "checkmark")
            }
        }
        Divider()
        if task.status == .done {
            if task.isArchived {
                Button {
                    restoreTask()
                } label: {
                    Label("Restore from Archive", systemImage: "archivebox")
                }
            } else {
                Button {
                    archiveTask()
                } label: {
                    Label("Archive Completed Task", systemImage: "archivebox.fill")
                }
            }
            Divider()
        }
        Button(role: .destructive) {
            withAnimation { delete() }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func performStatusTransition(to status: TaskStatus) {
        guard task.status != status else { return }

        if status == .inProgress && isFocusGuardEnabled && inProgressTasks.count >= maxActiveTasks {
            triggerLimitFeedback()
            return
        }

        let previousStatus = task.status
        let destinationOrder = nextOrder(for: status)
        task.status = status
        task.order = destinationOrder
        task.updatedAt = Date()
        reorderTasks(in: previousStatus)
        reorderTasks(in: status)
        lastMovedStatus = status
        try? modelContext.save()
    }

    private func triggerLimitFeedback() {
        wipLimitHitCount += 1
        withAnimation(AppStyle.Motion.standardSpring) {
            wipLimitError = true
        }
        showingWIPLimitAlert = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppStyle.Motion.feedbackDismissDelay) {
            withAnimation(AppStyle.Motion.standardSpring) {
                wipLimitError = false
            }
        }
    }

    private func delete() {
        modelContext.delete(task)
        try? modelContext.save()
    }

    private func archiveTask() {
        task.archive()
        reorderTasks(in: .done)
        try? modelContext.save()
    }

    private func restoreTask() {
        task.restoreFromArchive()
        task.order = nextOrder(for: .done)
        reorderTasks(in: .done)
        try? modelContext.save()
    }

    private func nextOrder(for status: TaskStatus) -> Int {
        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = (try? modelContext.fetch(descriptor)) ?? []

        return allTasks
            .filter { $0.status == status && !$0.isArchived && $0.id != task.id }
            .count
    }

    private func reorderTasks(in status: TaskStatus) {
        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = (try? modelContext.fetch(descriptor)) ?? []
        let sortedTasks = allTasks
            .filter { $0.status == status && !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                if lhs.order != rhs.order {
                    return lhs.order < rhs.order
                }
                return lhs.createdAt < rhs.createdAt
            }

        for (index, item) in sortedTasks.enumerated() {
            item.order = index
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

private struct TaskBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: AppStyle.Spacing.tiny) {
            Image(systemName: systemImage)
                .font(AppStyle.Typography.iconTiny)

            Text(text)
                .lineLimit(1)
        }
        .font(AppStyle.Typography.pillLabel)
        .foregroundStyle(tint)
        .padding(.horizontal, AppStyle.Spacing.pillHorizontalPadding)
        .padding(.vertical, AppStyle.Spacing.pillVerticalPadding)
        .background(tint.opacity(AppStyle.Opacity.accentWashStrong), in: Capsule())
        .overlay(
            Capsule()
                .stroke(tint.opacity(AppStyle.Opacity.accentBorder), lineWidth: AppStyle.Shapes.borderWidth)
        )
        .accessibilityHidden(true)
    }
}

private extension View {
    @ViewBuilder
    func taskCardSwipeActions(
        configuration: TaskCardView.SwipeConfiguration,
        task: TaskItem,
        onMove: @escaping (TaskStatus) -> Void,
        onArchive: @escaping () -> Void,
        onRestore: @escaping () -> Void
    ) -> some View {
#if os(iOS)
        switch configuration {
        case .disabled:
            self
        case .listStatusActions:
            self
                .swipeActions(edge: .leading, allowsFullSwipe: task.status != .done) {
                    switch task.status {
                    case .todo:
                        Button {
                            onMove(.inProgress)
                        } label: {
                            Label("Move to In Progress", systemImage: "arrow.right.circle")
                        }
                        .tint(AppStyle.Colors.Status.inProgress)

                    case .inProgress:
                        Button {
                            onMove(.done)
                        } label: {
                            Label("Mark Done", systemImage: "checkmark.circle")
                        }
                        .tint(AppStyle.Colors.Status.done)

                    case .done:
                        if task.isArchived {
                            Button {
                                onRestore()
                            } label: {
                                Label("Restore", systemImage: "archivebox")
                            }
                            .tint(AppStyle.Colors.Status.done)
                        } else {
                            Button {
                                onArchive()
                            } label: {
                                Label("Archive", systemImage: "archivebox.fill")
                            }
                            .tint(AppStyle.Colors.secondaryText)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: task.status == .inProgress) {
                    switch task.status {
                    case .todo:
                        EmptyView()

                    case .inProgress:
                        Button {
                            onMove(.todo)
                        } label: {
                            Label("Move to To Do", systemImage: "arrow.left.circle")
                        }
                        .tint(AppStyle.Colors.Status.todo)

                    case .done:
                        Button {
                            onMove(.todo)
                        } label: {
                            Label("Move to To Do", systemImage: "arrow.left.circle")
                        }
                        .tint(AppStyle.Colors.Status.todo)

                        Button {
                            onMove(.inProgress)
                        } label: {
                            Label("Move to In Progress", systemImage: "arrow.left.circle")
                        }
                        .tint(AppStyle.Colors.Status.inProgress)
                    }
                }
        }
#else
        self
#endif
    }
}

private func previewTask(
    title: String,
    description: String,
    status: TaskStatus,
    priority: TaskPriority,
    isBlocked: Bool = false,
    order: Int = 0
) -> TaskItem {
    TaskItem(
        title: title,
        description: description,
        status: status,
        priority: priority,
        isBlocked: isBlocked,
        order: order
    )
}

private func taskCardPreview(_ tasks: [TaskItem]) -> some View {
    ScrollView {
        VStack(spacing: AppStyle.Spacing.medium) {
            ForEach(tasks) { task in
                TaskCardView(
                    task: task,
                    onSelect: { _ in },
                    swipeConfiguration: .listStatusActions
                )
            }
        }
        .padding(AppStyle.Spacing.normal)
    }
    .background(AppStyle.Colors.background)
    .modelContainer(for: TaskItem.self, inMemory: true)
}

#Preview("Ready / To Do") {
    taskCardPreview([
        previewTask(
            title: "Draft release notes",
            description: "Summarize the latest board updates for the next TestFlight build.",
            status: .todo,
            priority: .medium
        )
    ])
}

#Preview("In Progress") {
    taskCardPreview([
        previewTask(
            title: "Refine swipe interactions",
            description: "Validate the left and right swipe affordances in the list views.",
            status: .inProgress,
            priority: .medium
        )
    ])
}

#Preview("Blocked") {
    taskCardPreview([
        previewTask(
            title: "Waiting on App Review notes",
            description: "A follow-up from the release checklist is blocked until the previous build gets feedback.",
            status: .inProgress,
            priority: .high,
            isBlocked: true
        )
    ])
}

#Preview("Closed / Done") {
    taskCardPreview([
        previewTask(
            title: "Ship task card iteration",
            description: "The swipe pattern is approved and ready for release.",
            status: .done,
            priority: .low
        )
    ])
}

#Preview("Priority Mix") {
    taskCardPreview([
        previewTask(title: "High priority follow-up", description: "Tight feedback loop for a release issue.", status: .todo, priority: .high, order: 0),
        previewTask(title: "Medium effort polish", description: "Refine spacing and hierarchy in the task list.", status: .inProgress, priority: .medium, order: 1),
        previewTask(title: "Low pressure cleanup", description: "Archive old notes and remove stale copy.", status: .done, priority: .low, order: 2)
    ])
}

#Preview("Long Content") {
    taskCardPreview([
        previewTask(
            title: "Prepare a longer task title that still needs to read cleanly on compact iPhone widths without crowding the badges or drag affordance",
            description: "This description is intentionally longer so the Canvas preview shows how three lines wrap inside the card while preserving the same relaxed spacing, muted helper tone, and native feel used throughout the Dashboard surfaces.",
            status: .todo,
            priority: .high
        )
    ])
}

#Preview("Large Dynamic Type") {
    taskCardPreview([
        previewTask(
            title: "Accessibility pass for task cards",
            description: "Verify titles, badges, metadata, and actions continue to fit at larger sizes.",
            status: .inProgress,
            priority: .medium
        )
    ])
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark Mode") {
    taskCardPreview([
        previewTask(
            title: "Night review",
            description: "Check the soft surfaces and muted text balance in dark appearance.",
            status: .done,
            priority: .medium
        )
    ])
    .preferredColorScheme(.dark)
}
