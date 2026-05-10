import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query(sort: \TaskItem.order) private var allTasks: [TaskItem]
    @State private var selectedTab = 0
    @State private var selectedSegment: TaskStatus = .todo
    @State private var isAddingTask = false
    @State private var addTaskStatus: TaskStatus = .todo

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            GlassTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, AppStyle.Spacing.normal)
                .padding(.bottom, AppStyle.Spacing.small)
        }
        .ignoresSafeArea(.keyboard)
        .syncAppIconBadge(tasks: allTasks)
        .sheet(isPresented: $isAddingTask) {
            AddTaskView(status: addTaskStatus)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            NavigationStack {
                DashboardView(
                    allTasks: allTasks,
                    onAddTask: {
                        addTaskStatus = .todo
                        isAddingTask = true
                    },
                    onSelectStatus: { status in
                        selectedSegment = status
                        withAnimation(.snappy) {
                            selectedTab = 1
                        }
                    }
                )
            }
        case 1:
            NavigationStack {
                AllTasksView(
                    allTasks: allTasks,
                    selectedSegment: $selectedSegment,
                    onAddTask: {
                        addTaskStatus = selectedSegment
                        isAddingTask = true
                    }
                )
            }
        case 2:
            NavigationStack {
                SettingsView()
            }
        default:
            EmptyView()
        }
    }
}

private struct GlassTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: AppStyle.Spacing.none) {
            tabButton(index: 0, icon: "house", selectedIcon: "house.fill", title: "Dashboard")
            tabButton(index: 1, icon: "checklist", selectedIcon: "checklist", title: "All Tasks")
            tabButton(index: 2, icon: "gearshape", selectedIcon: "gearshape.fill", title: "Settings")
        }
        .padding(.horizontal, AppStyle.Spacing.extraLarge)
        .padding(.vertical, AppStyle.Spacing.small)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.tabBarCornerRadius, style: .continuous))
        .shadow(
            color: AppStyle.Colors.cardShadow,
            radius: AppStyle.Shapes.cardShadowRadius,
            y: -AppStyle.Shapes.cardShadowY
        )
    }

    private func tabButton(index: Int, icon: String, selectedIcon: String, title: String) -> some View {
        let isSelected = selectedTab == index
        return Button {
            withAnimation(.snappy) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: AppStyle.Spacing.tabBarIconGap) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: AppStyle.Shapes.iconSizeMedium, weight: .semibold))
                Text(title)
                    .font(AppStyle.Typography.tabLabel)
            }
            .foregroundStyle(isSelected ? AppStyle.Colors.Status.todo : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppStyle.Spacing.tiny)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
