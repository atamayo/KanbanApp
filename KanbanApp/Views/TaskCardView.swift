import SwiftUI
import SwiftData

struct TaskCardView: View {
    let task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @State private var showingDetail = false

    private var statusColor: Color {
        switch task.status {
        case .todo: return .blue
        case .inProgress: return .orange
        case .done: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(task.status == .done ? .secondary : .primary)
                    .strikethrough(task.status == .done)
                Spacer()
                if task.status == .done {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            if !task.desc.isEmpty {
                Text(task.desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                Text(task.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if task.status == .inProgress {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(statusColor)
                .frame(width: 4)
        }
        .onTapGesture { showingDetail = true }
        .contextMenu { contextMenuItems }
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        if task.status != .todo {
            Button { move(.todo) } label: {
                Label("Move to To Do", systemImage: "arrow.left")
            }
        }
        if task.status != .inProgress {
            Button { move(.inProgress) } label: {
                Label("Move to In Progress", systemImage: "arrow.right")
            }
        }
        if task.status != .done {
            Button { move(.done) } label: {
                Label("Mark Done", systemImage: "checkmark")
            }
        }
        Divider()
        Button(role: .destructive) {
            withAnimation { delete() }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func move(_ status: TaskStatus) {
        task.status = status
        task.updatedAt = Date()
        try? modelContext.save()
    }

    private func delete() {
        modelContext.delete(task)
        try? modelContext.save()
    }
}
