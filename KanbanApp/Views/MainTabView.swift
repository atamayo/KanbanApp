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
        tabContent
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
                            withAnimation(AppStyle.Motion.snappy) {
                                selectedTab = .tasks
                            }
                        }
                    )
                    .toolbar {
                        addTaskToolbarItem
                    }
                }
            }

            Tab("All Tasks", systemImage: "checklist", value: .tasks) {
                NavigationStack {
                    AllTasksView(
                        allTasks: allTasks,
                        selectedSegment: $selectedSegment
                    )
                    .toolbar {
                        addTaskToolbarItem
                    }
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

    @ToolbarContentBuilder
    private var addTaskToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: presentAddTask) {
                Label("Add Task", systemImage: "plus")
            }
            .labelStyle(.titleAndIcon)
            .buttonStyle(.glassProminent)
            .accessibilityLabel("Add Task")
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

#Preview("Main Tabs") {
    MainTabView()
        .modelContainer(MainTabViewPreview.container)
}

@MainActor
private enum MainTabViewPreview {
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TaskItem.self, configurations: configuration)
        let context = container.mainContext

        [
            TaskItem(
                title: "Plan sprint goals",
                description: "Define the next iteration outcome for the board refresh.",
                completionCriteria: "Sprint goal shared with the team",
                status: .todo,
                priority: .high,
                order: 0
            ),
            TaskItem(
                title: "Refine onboarding copy",
                description: "Tighten the opening walkthrough so it reads clearly.",
                completionCriteria: "Three onboarding pages reviewed",
                status: .todo,
                priority: .medium,
                order: 1
            ),
            TaskItem(
                title: "Polish task card layout",
                description: "Adjust spacing and hierarchy for active work.",
                completionCriteria: "Updated layout approved on iPhone and iPad",
                status: .inProgress,
                priority: .high,
                order: 0
            ),
            TaskItem(
                title: "Ship search improvements",
                description: "Complete the last pass on task discovery.",
                completionCriteria: "Search tab behavior validated",
                status: .done,
                priority: .medium,
                order: 0
            )
        ].forEach { context.insert($0) }

        return container
    }()
}
