import SwiftUI
import SwiftData

struct AllTasksView: View {
    @Environment(\.modelContext) private var modelContext
    let allTasks: [TaskItem]
    @Binding var selectedSegment: TaskStatus
    var onAddTask: (() -> Void)? = nil
    
    @State private var selectedTask: TaskItem?
    @State private var searchText = ""
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3

    private var filteredTasks: [TaskItem] {
        allTasks
            .filter { task in
                let matchesStatus = task.status == selectedSegment
                let matchesSearch = searchText.isEmpty || task.title.localizedCaseInsensitiveContains(searchText) || task.desc.localizedCaseInsensitiveContains(searchText)
                return matchesStatus && matchesSearch
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
            // Search Bar
            searchBar
                .padding(.horizontal, AppStyle.Spacing.normal)
                .padding(.top, AppStyle.Spacing.small)

            // Sliding Pill Status Picker
            StatusPicker(selection: $selectedSegment)
                .padding(.horizontal, AppStyle.Spacing.normal)
                .padding(.vertical, AppStyle.Spacing.medium)

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
            }
        }
        .background(AppStyle.Colors.background)
        .navigationTitle("All Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onAddTask?()
                } label: {
                    Image(systemName: "plus")
                        .font(AppStyle.Typography.bodyLarge)
                        .foregroundStyle(AppStyle.Colors.Status.todo)
                        .frame(width: AppStyle.Shapes.buttonSizeMedium, height: AppStyle.Shapes.buttonSizeMedium)
                        .background(.ultraThinMaterial, in: .circle)
                        .overlay(
                            Circle()
                                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                        )
                        .shadow(
                            color: AppStyle.Colors.cardShadow,
                            radius: AppStyle.Shapes.tinyShadowRadius,
                            x: AppStyle.Spacing.none,
                            y: AppStyle.Shapes.tinyShadowY
                        )
                }
                .opacity(selectedSegment == .todo && isWIPLimitReached ? 0.65 : 1.0)
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
                .presentationSizing(.form)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search tasks...", text: $searchText)
                .font(AppStyle.Typography.statusLabel)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppStyle.Spacing.small)
        .background(AppStyle.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.tinyCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Shapes.tinyCornerRadius)
                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
        )
    }

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(AppStyle.Typography.emptyIcon)
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No tasks" : "No results")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(.primary)
            Text(searchText.isEmpty ? "No tasks in this status" : "Try a different search term")
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

    var body: some View {
        HStack(spacing: AppStyle.Spacing.none) {
            ForEach(TaskStatus.allCases) { status in
                Text(status.rawValue)
                    .font(AppStyle.Typography.tabLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppStyle.Spacing.totalRowVertical)
                    .foregroundStyle(selection == status ? .white : AppStyle.Colors.subtleText)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.3)) { selection = status }
                    }
            }
        }
        .background {
            GeometryReader { geo in
                let segmentWidth = geo.size.width / CGFloat(TaskStatus.allCases.count)
                let index = CGFloat(TaskStatus.allCases.firstIndex(of: selection) ?? 0)
                Capsule()
                    .fill(tintColor(for: selection))
                    .frame(width: max(segmentWidth - AppStyle.Spacing.small, AppStyle.Spacing.none))
                    .offset(x: AppStyle.Spacing.tiny + segmentWidth * index)
            }
            .animation(.snappy(duration: 0.3), value: selection)
        }
        .padding(AppStyle.Spacing.tiny)
        .background(AppStyle.Colors.surface)
        .clipShape(Capsule())
    }

    private func tintColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo: return AppStyle.Colors.Status.todo
        case .inProgress: return AppStyle.Colors.Status.inProgress
        case .done: return AppStyle.Colors.Status.done
        }
    }
}
