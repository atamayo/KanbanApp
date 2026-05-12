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
                        TaskCardView(
                            task: task,
                            onSelect: { selectedTask = $0 },
                            swipeConfiguration: .listStatusActions
                        )
                            .listRowInsets(EdgeInsets(top: AppStyle.Spacing.tiny, leading: AppStyle.Spacing.cardPadding, bottom: AppStyle.Spacing.tiny, trailing: AppStyle.Spacing.cardPadding))
                            .listRowSeparator(.hidden)
                            .listRowBackground(AppStyle.Colors.clear)
                    }
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
                .foregroundStyle(AppStyle.Colors.secondaryText)
            Text("Search your work")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)
            Text("Find tasks by title, description, or definition of done.")
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(AppStyle.Colors.secondaryText)
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
                .foregroundStyle(AppStyle.Colors.secondaryText)
            Text("No matching tasks")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)
            Text("Try a different search term.")
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(AppStyle.Colors.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
