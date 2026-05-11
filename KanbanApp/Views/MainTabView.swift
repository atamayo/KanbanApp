import SwiftUI
import SwiftData

struct MainTabView: View {
    private enum AppTab: Int, Hashable {
        case dashboard
        case tasks
        case search
        case settings
    }

    @Query(sort: \TaskItem.order) private var allTasks: [TaskItem]
    @State private var selectedTab: AppTab = .dashboard
    @State private var selectedSegment: TaskStatus = .todo
    @State private var isAddingTask = false
    @State private var addTaskStatus: TaskStatus = .todo
    @State private var searchText = ""

    private var inProgressCount: Int {
        allTasks.filter { $0.status == .inProgress }.count
    }

    private var showsAddAccessory: Bool {
        switch selectedTab {
        case .dashboard, .tasks:
            return true
        case .search, .settings:
            return false
        }
    }

    var body: some View {
        tabContent
            .tabViewBottomAccessory(isEnabled: showsAddAccessory) {
                AddTaskAccessoryButton(action: presentAddTask)
            }
        .tabViewSearchActivation(.searchTabSelection)
        .tabBarMinimizeBehavior(.onScrollDown)
        .ignoresSafeArea(.keyboard)
        .syncAppIconBadge(tasks: allTasks)
        .sheet(isPresented: $isAddingTask) {
            AddTaskView(status: addTaskStatus)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house", value: .dashboard) {
                NavigationStack {
                    DashboardView(
                        allTasks: allTasks,
                        onSelectStatus: { status in
                            selectedSegment = status
                            withAnimation(.snappy) {
                                selectedTab = .tasks
                            }
                        }
                    )
                }
            }

            Tab("All Tasks", systemImage: "checklist", value: .tasks) {
                NavigationStack {
                    AllTasksView(
                        allTasks: allTasks,
                        selectedSegment: $selectedSegment
                    )
                }
            }
            .badge(inProgressCount > 0 ? inProgressCount : 0)

            Tab(value: .search, role: .search) {
                NavigationStack {
                    SearchTasksView(allTasks: allTasks, searchText: $searchText)
                }
                .searchable(text: $searchText, prompt: "Search tasks")
                .searchToolbarBehavior(.minimize)
                .searchPresentationToolbarBehavior(.avoidHidingContent)
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }

    private func presentAddTask() {
        switch selectedTab {
        case .dashboard:
            addTaskStatus = .todo
        case .tasks:
            addTaskStatus = selectedSegment
        case .search, .settings:
            addTaskStatus = .todo
        }

        isAddingTask = true
    }
}

private struct AddTaskAccessoryButton: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    let action: () -> Void

    private var horizontalPadding: CGFloat {
        placement == .inline ? 12 : 16
    }

    private var verticalPadding: CGFloat {
        placement == .inline ? 8 : 10
    }

    var body: some View {
        HStack {
            Button(action: action) {
                Label("Add Task", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: placement == .inline ? nil : .infinity)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }
}
