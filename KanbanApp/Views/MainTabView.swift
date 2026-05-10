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

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house", value: .dashboard) {
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
                        selectedSegment: $selectedSegment,
                        onAddTask: {
                            addTaskStatus = selectedSegment
                            isAddingTask = true
                        }
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
}
