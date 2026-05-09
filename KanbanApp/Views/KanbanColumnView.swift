import SwiftUI

struct KanbanColumnView: View {
    let tasks: [TaskItem]
    let status: TaskStatus
    let width: CGFloat
    let onMove: (UUID) -> Void

    private var columnColor: Color {
        switch status {
        case .todo: return .blue
        case .inProgress: return .orange
        case .done: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(tasks) { task in
                        TaskCardView(task: task)
                            .onDrag {
                                NSItemProvider(object: task.id.uuidString as NSString)
                            }
                    }
                    Color.clear.frame(height: 80)
                }
            }
            .scrollIndicators(.hidden)
            .dropDestination(for: String.self) { items, _ in
                guard let id = items.first, let uuid = UUID(uuidString: id),
                      !tasks.contains(where: { $0.id == uuid })
                else { return false }
                onMove(uuid)
                return true
            }
        }
        .frame(width: width)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(columnColor)
                .frame(width: 10, height: 10)
            Text(status.rawValue)
                .font(.headline.weight(.semibold))
            Spacer()
            Text("\(tasks.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.secondary.opacity(0.15), in: .capsule)
        }
    }
}
