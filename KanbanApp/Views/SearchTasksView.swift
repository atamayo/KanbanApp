import SwiftUI

struct SearchTasksView: View {
    let allTasks: [TaskItem]
    @Binding var searchText: String

    @State private var selectedTask: TaskItem?

    private var filteredTasks: [TaskItem] {
        let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }

        return allTasks
            .filter { task in
                task.title.localizedCaseInsensitiveContains(normalizedQuery) ||
                task.desc.localizedCaseInsensitiveContains(normalizedQuery) ||
                task.completionCriteria.localizedCaseInsensitiveContains(normalizedQuery)
            }
            .sorted { lhs, rhs in
                if lhs.status.sortOrder != rhs.status.sortOrder {
                    return lhs.status.sortOrder < rhs.status.sortOrder
                }
                if lhs.order != rhs.order {
                    return lhs.order < rhs.order
                }
                return lhs.createdAt > rhs.createdAt
            }
    }

    var body: some View {
        Group {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                promptState
            } else if filteredTasks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        TaskCardView(task: task, onSelect: { selectedTask = $0 })
                            .listRowInsets(EdgeInsets(top: AppStyle.Spacing.tiny, leading: AppStyle.Spacing.cardPadding, bottom: AppStyle.Spacing.tiny, trailing: AppStyle.Spacing.cardPadding))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppStyle.Colors.background)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
                .presentationSizing(.form)
        }
    }

    private var promptState: some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(AppStyle.Typography.emptyIcon)
                .foregroundStyle(.secondary)
            Text("Search your work")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(.primary)
            Text("Find tasks by title, description, or definition of done.")
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Spacer()
            Image(systemName: "tray")
                .font(AppStyle.Typography.emptyIcon)
                .foregroundStyle(.secondary)
            Text("No matching tasks")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(.primary)
            Text("Try a different search term.")
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
