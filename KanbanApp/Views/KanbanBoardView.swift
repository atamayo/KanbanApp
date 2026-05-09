import SwiftUI
import SwiftData

struct KanbanBoardView: View {
    @Query(sort: \TaskItem.order) private var allTasks: [TaskItem]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAdd = false
    @State private var addStatus: TaskStatus = .todo

    private func tasks(for status: TaskStatus) -> [TaskItem] {
        allTasks.filter { $0.status == status }
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(TaskStatus.allCases) { status in
                        KanbanColumnView(
                            tasks: tasks(for: status),
                            status: status,
                            width: max(geo.size.width * 0.75, 300),
                            onMove: { id in
                                guard let task = allTasks.first(where: { $0.id == id }) else { return }
                                let count = tasks(for: status).count
                                withAnimation(.snappy) {
                                    task.status = status
                                    task.order = count
                                    task.updatedAt = Date()
                                    reorder(status: status)
                                    try? modelContext.save()
                                }
                            }
                        )
                        .dropDestination(for: String.self) { items, _ in
                            guard let id = items.first, let uuid = UUID(uuidString: id),
                                  allTasks.contains(where: { $0.id == uuid })
                            else { return false }
                            let count = tasks(for: status).count
                            if let task = allTasks.first(where: { $0.id == uuid }) {
                                withAnimation(.snappy) {
                                    task.status = status
                                    task.order = count
                                    task.updatedAt = Date()
                                    reorder(status: status)
                                    try? modelContext.save()
                                }
                                return true
                            }
                            return false
                        }
                    }
                }
                .padding(.horizontal, 16)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        .sheet(isPresented: $showingAdd) {
            AddTaskView(status: addStatus)
        }
    }

    private func reorder(status: TaskStatus) {
        let columnTasks = tasks(for: status).sorted { $0.order < $1.order }
        for (i, t) in columnTasks.enumerated() {
            t.order = i
        }
    }

    private var addButton: some View {
        Menu {
            ForEach(TaskStatus.allCases) { status in
                Button(status.rawValue) {
                    addStatus = status
                    showingAdd = true
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .circle
                )
                .shadow(color: .purple.opacity(0.4), radius: 12, y: 4)
        }
        .padding(24)
    }
}
