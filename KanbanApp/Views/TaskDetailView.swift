import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: TaskItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Buy groceries", text: $task.title, axis: .vertical)
                        .font(AppStyle.Typography.detailTitle)
                } header: {
                    Label("Title", systemImage: "pencil")
                }
                Section {
                    TextField("Description", text: $task.desc, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Label("Description", systemImage: "text.alignleft")
                }
                Section {
                    TextField("What does done look like?", text: $task.completionCriteria, axis: .vertical)
                        .lineLimit(1...3)
                } header: {
                    Label("Definition of Done", systemImage: "checklist")
                } footer: {
                    Text("Keep it compact. A short completion check helps you finish instead of endlessly refining.")
                }
                Section {
                    Picker("Status", selection: $task.status) {
                        ForEach(TaskStatus.allCases) { s in
                            HStack {
                                Circle()
                                    .fill(statusColor(s))
                                    .frame(width: AppStyle.Shapes.dotSize, height: AppStyle.Shapes.dotSize)
                                Text(s.rawValue)
                            }
                            .tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("Status", systemImage: "arrow.triangle.branch")
                }
                Section {
                    Toggle(isOn: blockedBinding) {
                        Label("Blocked / Waiting", systemImage: task.isBlocked ? "pause.circle.fill" : "pause.circle")
                    }
                    .disabled(task.status != .inProgress)
                } header: {
                    Label("Flow State", systemImage: "scope")
                } footer: {
                    if task.status == .inProgress {
                        Text("Use this when work cannot move forward yet. Blocked tasks should become visible quickly.")
                    } else {
                        Text("Blocked state is only available for tasks that are currently in progress.")
                    }
                }
                Section {
                    Picker("Priority", selection: $task.priorityRaw) {
                        ForEach(TaskPriority.allCases) { p in
                            HStack {
                                Image(systemName: priorityIcon(p))
                                    .foregroundStyle(priorityColor(p))
                                    .frame(width: AppStyle.Spacing.iconFrameWidth)
                                Text(p.rawValue)
                            }
                            .tag(p.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("Priority", systemImage: "flag")
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
                    if let closedAt {
                        HStack {
                            Label("Closed", systemImage: "checkmark.seal")
                            Spacer()
                            VStack(alignment: .trailing, spacing: AppStyle.Spacing.tiny) {
                                Text(closedAt, style: .date)
                                Text(closedAt, style: .time)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Info", systemImage: "info.circle")
                }
                Section {
                    Button(role: .destructive) {
                        task.modelContext?.delete(task)
                        try? task.modelContext?.save()
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
                    Button("Done") {
                        task.updatedAt = Date()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                try? task.modelContext?.save()
            }
        }
    }

    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .todo: return AppStyle.Colors.Status.todo
        case .inProgress: return AppStyle.Colors.Status.inProgress
        case .done: return AppStyle.Colors.Status.done
        }
    }

    private var closedAt: Date? {
        guard task.status == .done else { return nil }
        return task.finalizedAt ?? task.updatedAt
    }

    private func priorityIcon(_ priority: TaskPriority) -> String {
        switch priority {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return AppStyle.Colors.Zone.high
        case .medium: return AppStyle.Colors.Zone.medium
        case .low: return AppStyle.Colors.Zone.low
        }
    }

    private var blockedBinding: Binding<Bool> {
        Binding(
            get: { task.isBlocked },
            set: { newValue in
                task.isBlocked = task.status == .inProgress ? newValue : false
                task.updatedAt = Date()
            }
        )
    }
}
