import SwiftUI
import SwiftData

struct AddTaskView: View {
    let status: TaskStatus
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                        .font(.body)
                } header: {
                    Label("Title", systemImage: "pencil")
                }
                Section {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.body)
                } header: {
                    Label("Description", systemImage: "text.alignleft")
                }
                Section {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(statusColor)
                        Text("Will be added to ")
                        Text(status.rawValue)
                            .fontWeight(.semibold)
                            .foregroundStyle(statusColor)
                    }
                    .font(.subheadline)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let order = (try? modelContext.fetch(FetchDescriptor<TaskItem>()).filter { $0.status == status }.count) ?? 0
                        let task = TaskItem(title: title, description: description, status: status, order: order)
                        modelContext.insert(task)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var statusColor: Color {
        switch status {
        case .todo: return .blue
        case .inProgress: return .orange
        case .done: return .green
        }
    }
}
