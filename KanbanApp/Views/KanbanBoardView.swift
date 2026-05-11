import SwiftUI
import SwiftData

struct KanbanBoardView: View {
    @Query(sort: \TaskItem.order) private var allTasks: [TaskItem]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTask: TaskItem?
    @State private var droppedTaskID: UUID?
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var showingWIPAlert = false

    private func triggerToast(message: String) {
        withAnimation(AppStyle.Motion.standardSpring) {
            toastMessage = message
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AppStyle.Motion.toastDismissDelay) {
            withAnimation(AppStyle.Motion.standardSpring) {
                showToast = false
            }
        }
    }

    private func tasks(for status: TaskStatus) -> [TaskItem] {
        allTasks
            .filter { $0.status == status }
            .sorted { a, b in
                if a.priority.sortOrder != b.priority.sortOrder {
                    return a.priority.sortOrder < b.priority.sortOrder
                }
                return a.order < b.order
            }
    }

    var body: some View {
        boardContent
            .navigationTitle("Kanban")
            .navigationBarTitleDisplayMode(.inline)
            .inspector(isPresented: .init(
                get: { selectedTask != nil && horizontalSizeClass == .regular },
                set: { if !$0 { selectedTask = nil } }
            )) {
                detailSheet
                    .inspectorColumnWidth(min: AppStyle.Shapes.inspectorMinWidth, ideal: AppStyle.Shapes.inspectorIdealWidth)
            }
            .sheet(isPresented: .init(
                get: { selectedTask != nil && horizontalSizeClass != .regular },
                set: { if !$0 { selectedTask = nil } }
            )) {
                detailSheet
                    .presentationSizing(.form)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WIPLimitReached"))) { _ in
                showingWIPAlert = true
                let inProgressTasks = allTasks.filter { $0.status == .inProgress }
                if let exampleTask = inProgressTasks.first {
                    triggerToast(message: "You're at peak capacity! Finishing '\(exampleTask.title)' will free up space.")
                } else {
                    triggerToast(message: "Limit Reached")
                }
            }
            .customAlert(
                isPresented: $showingWIPAlert,
                iconName: "brain.head.profile",
                title: "WIP Limit Reached",
                message: "Personal Kanban recommends a WIP limit of 2 or 3 to minimize context-switching and finish tasks faster."
            )
            .overlay(alignment: .top) {
                if showToast {
                    Text(toastMessage ?? "")
                        .font(AppStyle.Typography.formFooter)
                        .padding(.horizontal, AppStyle.Spacing.normal)
                        .padding(.vertical, AppStyle.Spacing.tiny)
                        .background(AppStyle.Colors.warning.opacity(AppStyle.Opacity.toast))
                        .foregroundStyle(AppStyle.Colors.inverseText)
                        .clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, AppStyle.Spacing.toastTopPadding)
                }
            }
            .sensoryFeedback(.success, trigger: droppedTaskID)
    }

    @ViewBuilder
    private var boardContent: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppStyle.Spacing.boardHStackGap) {
                    ForEach(TaskStatus.allCases) { status in
                        KanbanColumnView(
                            tasks: tasks(for: status),
                            status: status,
                            width: min(max(geo.size.width * AppStyle.Shapes.columnWidthRatio, AppStyle.Shapes.columnMinWidth), AppStyle.Shapes.columnMaxWidth),
                            onDrop: { id, priority in
                                withAnimation(AppStyle.Motion.snappy) {
                                    move(id, to: status, priority: priority)
                                }
                                droppedTaskID = id
                            },
                            onSelect: { selectedTask = $0 }
                        )
                    }
                }
                .padding(.horizontal, AppStyle.Spacing.cardPadding)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollBounceBehavior(.basedOnSize)
            .scrollClipDisabled()
        }
    }

    @ViewBuilder
    private var detailSheet: some View {
        if let task = selectedTask {
            TaskDetailView(task: task)
        }
    }

    private func move(_ id: UUID, to status: TaskStatus, priority: TaskPriority) {
        guard let task = allTasks.first(where: { $0.id == id }) else { return }
        task.status = status
        task.priority = priority
        task.order = tasks(for: status).count
        task.updatedAt = Date()
        reorder(status: status)
        try? modelContext.save()
    }

    private func reorder(status: TaskStatus) {
        let sorted = tasks(for: status)
        for (i, t) in sorted.enumerated() {
            t.order = i
        }
    }
}
