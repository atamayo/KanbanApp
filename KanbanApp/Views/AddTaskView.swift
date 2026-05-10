import SwiftUI
import SwiftData

struct AddTaskView: View {
    let status: TaskStatus
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var quickCaptureText = ""
    @State private var title = ""
    @State private var description = ""
    @State private var completionCriteria = ""
    @State private var priority: TaskPriority = .medium
    @State private var isGeneratingQuickCapture = false
    @State private var quickCaptureMessage: String?
    @State private var showingWIPLimitAlert = false
    @FocusState private var focusedField: Field?
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0

    enum Field {
        case title
        case description
        case completionCriteria
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: AppStyle.Spacing.none) {
            header
            
            ScrollView {
                VStack(spacing: AppStyle.Spacing.extraLarge) {
                    quickCaptureSection
                    titleSection
                    descriptionSection
                    completionCriteriaSection
                    prioritySection
                    statusInfo
                }
                .padding(AppStyle.Spacing.extraLarge)
            }
            
            createButton
                .padding(AppStyle.Spacing.extraLarge)
        }
        .background(AppStyle.Colors.background)
        .onAppear { focusedField = .title }
        .customAlert(
            isPresented: $showingWIPLimitAlert,
            iconName: "brain.head.profile",
            title: "WIP Limit Reached",
            message: "Personal Kanban recommends a WIP limit of 2 or 3 to minimize context-switching and finish tasks faster. Finish or move an active task before adding another In Progress task."
        )
    }

    private var quickCaptureSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Capture AI")
                        .font(AppStyle.Typography.sectionTitle)
                        .foregroundStyle(.secondary)
                        .tracking(AppStyle.Typography.sectionTracking)

                    Text("Paste a messy thought and turn it into a clean task draft.")
                        .font(AppStyle.Typography.guidanceFooter)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task { await generateTaskDraft() }
                } label: {
                    HStack(spacing: 8) {
                        if isGeneratingQuickCapture {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "apple.intelligence")
                        }

                        Text(isGeneratingQuickCapture ? "Thinking…" : "Generate")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minWidth: 118)
                }
                .buttonStyle(.glass)
                .disabled(quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGeneratingQuickCapture || !isQuickCaptureAvailable)
            }

            TextField("Paste notes, a brain dump, or a rough idea…", text: $quickCaptureText, axis: .vertical)
                .font(.body)
                .lineLimit(4...8)
                .padding(AppStyle.Spacing.normal)
                .background(AppStyle.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                        .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                )

            if let quickCaptureMessage {
                Text(quickCaptureMessage)
                    .font(AppStyle.Typography.guidanceFooter)
                    .foregroundStyle(isQuickCaptureAvailable ? .secondary : AppStyle.Colors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !isQuickCaptureAvailable, let unavailableMessage = quickCaptureUnavailableMessage {
                Text(unavailableMessage)
                    .font(AppStyle.Typography.guidanceFooter)
                    .foregroundStyle(AppStyle.Colors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.body)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("New Task")
                .font(AppStyle.Typography.headerTitle)
            
            Spacer()
            
            Button("Cancel") { dismiss() }
                .font(.body)
                .opacity(0)
                .disabled(true)
        }
        .padding(.horizontal, AppStyle.Spacing.extraLarge)
        .padding(.vertical, AppStyle.Spacing.large)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.5)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Title")
                .font(AppStyle.Typography.sectionTitle)
                .foregroundStyle(.secondary)
                .tracking(AppStyle.Typography.sectionTracking)
            
            TextField("What needs to be done?", text: $title)
                .font(.body)
                .padding(AppStyle.Spacing.normal)
                .background(AppStyle.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                        .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                )
                .focused($focusedField, equals: .title)
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Priority")
                .font(AppStyle.Typography.sectionTitle)
                .foregroundStyle(.secondary)
                .tracking(AppStyle.Typography.sectionTracking)
            
            HStack(spacing: AppStyle.Spacing.medium) {
                ForEach(TaskPriority.allCases) { p in
                    Button {
                        withAnimation(.snappy) { priority = p }
                    } label: {
                        VStack(spacing: AppStyle.Spacing.small) {
                            Image(systemName: priorityIcon(p))
                                .font(.title3)
                            Text(p.rawValue)
                                .font(AppStyle.Typography.priorityLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppStyle.Spacing.medium)
                        .background(priority == p ? priorityColor(p).opacity(0.15) : AppStyle.Colors.surface)
                        .foregroundStyle(priority == p ? priorityColor(p) : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                                .stroke(priority == p ? priorityColor(p).opacity(0.5) : AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Description")
                .font(AppStyle.Typography.sectionTitle)
                .foregroundStyle(.secondary)
                .tracking(AppStyle.Typography.sectionTracking)

            TextField("Add context for the task", text: $description, axis: .vertical)
                .font(.body)
                .lineLimit(3...6)
                .padding(AppStyle.Spacing.normal)
                .background(AppStyle.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                        .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                )
                .focused($focusedField, equals: .description)
        }
    }

    private var completionCriteriaSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Definition of Done")
                .font(AppStyle.Typography.sectionTitle)
                .foregroundStyle(.secondary)
                .tracking(AppStyle.Typography.sectionTracking)

            TextField("What does done look like?", text: $completionCriteria, axis: .vertical)
                .font(.body)
                .lineLimit(2...4)
                .padding(AppStyle.Spacing.normal)
                .background(AppStyle.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                        .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                )
                .focused($focusedField, equals: .completionCriteria)

            Text("Keep it short. A compact finish check makes it easier to close the task.")
                .font(AppStyle.Typography.guidanceFooter)
                .foregroundStyle(.secondary)
        }
    }

    private var statusInfo: some View {
        HStack(spacing: AppStyle.Spacing.medium) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(statusColor)
            
            Text("Adding to \(Text(status.rawValue).fontWeight(.bold)) status")
        } 
        .font(AppStyle.Typography.formFooter)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppStyle.Spacing.normal)
        .background(statusColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
    }

    private var createButton: some View {
        Button {
            addTask()
        } label: {
            Text("Create Task")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppStyle.Shapes.fabSize)
                .background(isValid ? AppStyle.Colors.Status.todo : Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous))
                .shadow(
                    color: (isValid ? AppStyle.Colors.Status.todo : Color.clear).opacity(0.3),
                    radius: AppStyle.Shapes.fabShadowRadius,
                    x: AppStyle.Spacing.none,
                    y: AppStyle.Shapes.fabShadowY
                )
        }
        .disabled(!isValid)
    }

    private var quickCaptureAvailability: QuickCaptureAvailability {
        QuickCaptureTaskGenerator.availability
    }

    private var isQuickCaptureAvailable: Bool {
        if case .available = quickCaptureAvailability {
            return true
        }
        return false
    }

    private var quickCaptureUnavailableMessage: String? {
        if case .unavailable(let message) = quickCaptureAvailability {
            return message
        }
        return nil
    }

    private func addTask() {
        guard isValid else { return }

        let allTasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []

        if status == .inProgress && isFocusGuardEnabled {
            let inProgressCount = allTasks.filter { $0.status == .inProgress }.count
            guard inProgressCount < maxActiveTasks else {
                wipLimitHitCount += 1
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingWIPLimitAlert = true
                return
            }
        }

        let order = allTasks.filter { $0.status == status }.count
        let task = TaskItem(
            title: title,
            description: description,
            completionCriteria: completionCriteria,
            status: status,
            priority: priority,
            order: order
        )
        modelContext.insert(task)
        try? modelContext.save()
        dismiss()
    }

    @MainActor
    private func generateTaskDraft() async {
        let cleanedText = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }
        guard isQuickCaptureAvailable else {
            quickCaptureMessage = quickCaptureUnavailableMessage
            return
        }

        isGeneratingQuickCapture = true
        quickCaptureMessage = nil

        defer { isGeneratingQuickCapture = false }

        do {
            let draft = try await QuickCaptureTaskGenerator.generate(from: cleanedText)
            title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)

            let cleanedDescription = draft.taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedNextAction = draft.nextAction.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedDone = draft.definitionOfDone.trimmingCharacters(in: .whitespacesAndNewlines)

            if cleanedDescription.isEmpty {
                description = cleanedNextAction.isEmpty ? "" : "Next action: \(cleanedNextAction)"
            } else if cleanedNextAction.isEmpty {
                description = cleanedDescription
            } else {
                description = "\(cleanedDescription)\n\nNext action: \(cleanedNextAction)"
            }

            completionCriteria = cleanedDone
            priority = QuickCaptureTaskGenerator.taskPriority(from: draft.priority)
            focusedField = .title
            quickCaptureMessage = "Draft generated. Review and adjust before creating the task."
        } catch {
            quickCaptureMessage = "Quick Capture AI couldn’t generate a draft right now. Try shortening the note and retry."
        }
    }

    private var statusColor: Color {
        switch status {
        case .todo: return AppStyle.Colors.Status.todo
        case .inProgress: return AppStyle.Colors.Status.inProgress
        case .done: return AppStyle.Colors.Status.done
        }
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
        case .high: return AppStyle.Colors.Priority.high
        case .medium: return AppStyle.Colors.Priority.medium
        case .low: return AppStyle.Colors.Priority.low
        }
    }
}
