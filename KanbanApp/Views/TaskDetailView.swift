import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @State private var suggestedNextAction = ""
    @State private var isGeneratingNextAction = false
    @State private var nextActionMessage: String?

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
                if task.status != .done {
                    nextActionSection
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
                if task.status == .inProgress {
                    Section {
                        Toggle(isOn: blockedBinding) {
                            Label("Blocked / Waiting", systemImage: task.isBlocked ? "pause.circle.fill" : "pause.circle")
                        }
                    } header: {
                        Label("Flow State", systemImage: "scope")
                    } footer: {
                        Text("Use this when work cannot move forward yet. Blocked tasks should become visible quickly.")
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
                            .foregroundStyle(AppStyle.Colors.secondaryText)
                    }
                    HStack {
                        Label("Updated", systemImage: "clock")
                        Spacer()
                        Text(task.updatedAt, style: .relative)
                            .foregroundStyle(AppStyle.Colors.secondaryText)
                    }
                    if let closedAt {
                        HStack {
                            Label("Closed", systemImage: "checkmark.seal")
                            Spacer()
                            VStack(alignment: .trailing, spacing: AppStyle.Spacing.tiny) {
                                Text(closedAt, style: .date)
                                Text(closedAt, style: .time)
                            }
                            .foregroundStyle(AppStyle.Colors.secondaryText)
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

    private var nextActionSection: some View {
        Section {
            Button {
                Task { await generateNextAction() }
            } label: {
                HStack {
                    if isGeneratingNextAction {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "apple.intelligence")
                    }
                    Text(isGeneratingNextAction ? "Generating…" : "Suggest Next Action")
                }
            }
            .disabled(isGeneratingNextAction || !isNextActionAvailable)

            if !suggestedNextAction.isEmpty {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                    Text(suggestedNextAction)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    HStack {
                        Button("Use Suggestion") {
                            applySuggestedNextAction()
                        }
                        Button("Try Again") {
                            Task { await generateNextAction() }
                        }
                    }
                    .font(AppStyle.Typography.formFooter)
                }
                .padding(.vertical, AppStyle.Spacing.tiny)
            }
        } header: {
            Label("Next Action", systemImage: "bolt.fill")
        } footer: {
            if let nextActionMessage {
                Text(nextActionMessage)
            } else if !isNextActionAvailable, let unavailableMessage = nextActionUnavailableMessage {
                Text(unavailableMessage)
            } else {
                Text("Generate one concrete next step to help restart motion on this task.")
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

    private var nextActionAvailability: QuickCaptureAvailability {
        NextActionSuggestionService.availability
    }

    private var isNextActionAvailable: Bool {
        if case .available = nextActionAvailability {
            return true
        }
        return false
    }

    private var nextActionUnavailableMessage: String? {
        if case .unavailable(let message) = nextActionAvailability {
            return message
        }
        return nil
    }

    @MainActor
    private func generateNextAction() async {
        guard isNextActionAvailable else {
            nextActionMessage = nextActionUnavailableMessage
            return
        }

        isGeneratingNextAction = true
        nextActionMessage = nil

        defer { isGeneratingNextAction = false }

        do {
            suggestedNextAction = try await NextActionSuggestionService.generate(for: task)
            nextActionMessage = "Review the suggestion before applying it to the task."
        } catch {
            nextActionMessage = "The app couldn’t generate a next action right now. Try again in a moment."
        }
    }

    private func applySuggestedNextAction() {
        guard !suggestedNextAction.isEmpty else { return }

        let suggestionLine = "Next action: \(suggestedNextAction)"
        let trimmedDescription = task.desc.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedDescription.isEmpty {
            task.desc = suggestionLine
        } else if trimmedDescription.contains(suggestionLine) {
            return
        } else {
            task.desc = "\(trimmedDescription)\n\n\(suggestionLine)"
        }

        task.updatedAt = Date()
        nextActionMessage = "Suggestion added to the task description."
    }
}
