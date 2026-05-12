import SwiftUI
import SwiftData

struct AllTasksView: View {
    @Environment(\.modelContext) private var modelContext
    let allTasks: [TaskItem]
    @Binding var selectedSegment: TaskStatus
    
    @State private var selectedTask: TaskItem?
    @State private var isShowingArchivedDone = false
    @Namespace private var glassChromeNamespace
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3

    private var filteredTasks: [TaskItem] {
        allTasks
            .filter { task in
                guard task.status == selectedSegment else { return false }
                if selectedSegment == .done {
                    return task.isArchived == isShowingArchivedDone
                }
                return !task.isArchived
            }
            .sorted { a, b in
                if a.order != b.order {
                    return a.order < b.order
                }
                return a.createdAt > b.createdAt
            }
    }

    private var inProgressCount: Int {
        allTasks.filter { $0.status == .inProgress && !$0.isArchived }.count
    }

    private var currentDoneCount: Int {
        allTasks.filter { $0.status == .done && !$0.isArchived }.count
    }

    private var archivedDoneCount: Int {
        allTasks.filter { $0.status == .done && $0.isArchived }.count
    }

    private var isWIPLimitReached: Bool {
        isFocusGuardEnabled && inProgressCount >= maxActiveTasks
    }

    var body: some View {
        VStack(spacing: AppStyle.Spacing.none) {
            GlassEffectContainer(spacing: AppStyle.Spacing.comfortable) {
                StatusPicker(selection: $selectedSegment, glassNamespace: glassChromeNamespace)
                    .padding(.horizontal, AppStyle.Spacing.normal)
                    .padding(.top, AppStyle.Spacing.small)
                    .padding(.bottom, AppStyle.Spacing.medium)
            }

            if selectedSegment == .todo && isWIPLimitReached {
                finishFirstBanner
                    .padding(.horizontal, AppStyle.Spacing.normal)
                    .padding(.bottom, AppStyle.Spacing.small)
            }

            if selectedSegment == .done {
                doneArchiveFilter
                    .padding(.horizontal, AppStyle.Spacing.normal)
                    .padding(.bottom, AppStyle.Spacing.small)
            }

            if filteredTasks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        TaskCardView(
                            task: task,
                            onSelect: { selectedTask = $0 },
                            swipeConfiguration: .listStatusActions
                        )
                            .listRowInsets(EdgeInsets(top: AppStyle.Spacing.tiny, leading: AppStyle.Spacing.cardPadding, bottom: AppStyle.Spacing.tiny, trailing: AppStyle.Spacing.cardPadding))
                            .listRowSeparator(.hidden)
                            .listRowBackground(AppStyle.Colors.clear)
                    }
                    .onMove(perform: moveTask)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, AppStyle.Spacing.tiny, for: .scrollContent)
                .contentMargins(.bottom, AppStyle.Spacing.extraLarge, for: .scrollContent)
                .contentMargins(.horizontal, AppStyle.Spacing.tiny, for: .scrollIndicators)
            }
        }
        .background(AppStyle.Colors.background)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .navigationTitle("All Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
                .presentationSizing(.form)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Spacer()
            Image(systemName: "tray")
                .font(AppStyle.Typography.emptyIcon)
                .foregroundStyle(AppStyle.Colors.secondaryText)
            Text("No tasks")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)
            Text(emptyStateMessage)
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(AppStyle.Colors.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateMessage: String {
        if selectedSegment == .done && isShowingArchivedDone {
            return "No archived Done tasks yet"
        }
        return "No tasks in this status"
    }

    private var doneArchiveFilter: some View {
        Picker("Done Filter", selection: $isShowingArchivedDone) {
            Text("Current \(currentDoneCount)")
                .tag(false)
            Text("Archived \(archivedDoneCount)")
                .tag(true)
        }
        .pickerStyle(.segmented)
        .tint(AppStyle.Colors.Status.done)
        .accessibilityLabel("Done task filter")
    }

    private var finishFirstBanner: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.statusRowGap) {
            Image(systemName: "flame.fill")
                .font(AppStyle.Typography.iconSmall)
                .foregroundStyle(AppStyle.Colors.warning)
                .padding(.top, AppStyle.Spacing.micro)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                Text("Finish one before pulling another.")
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(AppStyle.Colors.primaryText)

                Text("Your active lane is full. Review In Progress work before starting from To Do.")
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .background(AppStyle.Colors.warning.opacity(AppStyle.Opacity.accentWash), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.warning.opacity(AppStyle.Opacity.accentBorderStrong), lineWidth: AppStyle.Shapes.emphasizedBorderWidth)
        )
    }

    private func moveTask(from source: IndexSet, to destination: Int) {
        var updatedTasks = filteredTasks
        updatedTasks.move(fromOffsets: source, toOffset: destination)
        
        // Update order property for all tasks in this status to maintain the new sequence
        for (index, task) in updatedTasks.enumerated() {
            task.order = index
        }
        
        try? modelContext.save()
    }
}

private struct StatusPicker: View {
    @Binding var selection: TaskStatus
    let glassNamespace: Namespace.ID

    var body: some View {
        Picker("Status", selection: $selection) {
            ForEach(TaskStatus.allCases) { status in
                Text(status.rawValue)
                    .tag(status)
            }
        }
        .pickerStyle(.segmented)
        .tint(tintColor(for: selection))
        .controlSize(.large)
        .labelsHidden()
        .padding(AppStyle.Spacing.tight)
        .glassEffect(.regular.tint(AppStyle.Colors.glassTint), in: Capsule())
        .glassEffectID("status-picker", in: glassNamespace)
    }

    private func tintColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo: return AppStyle.Colors.Status.todo
        case .inProgress: return AppStyle.Colors.Status.inProgress
        case .done: return AppStyle.Colors.Status.done
        }
    }
}
