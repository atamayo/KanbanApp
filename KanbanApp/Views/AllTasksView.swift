import SwiftUI
import SwiftData

struct AllTasksView: View {
    @Environment(\.modelContext) private var modelContext
    let allTasks: [TaskItem]
    @Binding var selectedSegment: TaskStatus
    
    @State private var selectedTask: TaskItem?
    @Namespace private var glassChromeNamespace
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3

    private var filteredTasks: [TaskItem] {
        allTasks
            .filter { task in
                task.status == selectedSegment
            }
            .sorted { a, b in
                if a.order != b.order {
                    return a.order < b.order
                }
                return a.createdAt > b.createdAt
            }
    }

    private var inProgressCount: Int {
        allTasks.filter { $0.status == .inProgress }.count
    }

    private var isWIPLimitReached: Bool {
        isFocusGuardEnabled && inProgressCount >= maxActiveTasks
    }

    var body: some View {
        VStack(spacing: AppStyle.Spacing.none) {
            GlassEffectContainer(spacing: 18) {
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

            if filteredTasks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        TaskCardView(task: task, onSelect: { selectedTask = $0 })
                            .listRowInsets(EdgeInsets(top: AppStyle.Spacing.tiny, leading: AppStyle.Spacing.cardPadding, bottom: AppStyle.Spacing.tiny, trailing: AppStyle.Spacing.cardPadding))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
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
                .foregroundStyle(.secondary)
            Text("No tasks")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(.primary)
            Text("No tasks in this status")
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var finishFirstBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.warning)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Finish one before pulling another.")
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(.primary)

                Text("Your active lane is full. Review In Progress work before starting from To Do.")
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(AppStyle.Colors.warning.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppStyle.Colors.warning.opacity(0.18), lineWidth: 1)
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
        .padding(6)
        .glassEffect(.regular.tint(Color.white.opacity(0.04)), in: Capsule())
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
