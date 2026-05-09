import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @State var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title, axis: .vertical)
                        .font(.title3.weight(.semibold))
                } header: {
                    Label("Title", systemImage: "pencil")
                }
                Section {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Label("Description", systemImage: "text.alignleft")
                }
                Section {
                    Picker("Status", selection: $task.statusRaw) {
                        ForEach(TaskStatus.allCases) { s in
                            HStack {
                                Circle()
                                    .fill(statusColor(s))
                                    .frame(width: 8, height: 8)
                                Text(s.rawValue)
                            }
                            .tag(s.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("Status", systemImage: "arrow.triangle.branch")
                }
                Section {
                    HStack {
                        Label("Created", systemImage: "calendar")
                        Spacer()
                        Text(task.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Updated", systemImage: "clock")
                        Spacer()
                        Text(task.updatedAt, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Info", systemImage: "info.circle")
                }
                Section {
                    Button(role: .destructive) {
                        modelContext.delete(task)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        task.title = title
                        task.desc = description
                        task.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                title = task.title
                description = task.desc
            }
        }
    }

    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .todo: return .blue
        case .inProgress: return .orange
        case .done: return .green
        }
    }
}
