import SwiftData
import PhotosUI
import SwiftUI

struct AddTaskView: View {
    let status: TaskStatus
    var onTaskCreated: ((TaskItem) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var completionCriteria = ""
    @State private var priority: TaskPriority = .medium
    @State private var selectedQuickCapturePhoto: PhotosPickerItem?
    @State private var showingWIPLimitAlert = false
    @State private var showingQuickCaptureSheet = false
    @State private var showingPhotoPicker = false
    @State private var showingLiveTextScanner = false
    @State private var showingVoiceCapture = false
    @StateObject private var quickCapture = QuickCaptureCoordinator()
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
                    titleSection
                    descriptionSection
                    completionCriteriaSection
                    prioritySection
                    statusInfo
                }
                .padding(AppStyle.Spacing.extraLarge)
            }
            
            AddTaskActionBar(
                isImportingQuickCapturePhoto: quickCapture.isImportingPhoto,
                quickCaptureMessage: quickCapture.message,
                quickCaptureMessageColor: quickCaptureMessageColor,
                isQuickCaptureBusy: quickCapture.isGenerating || quickCapture.isImportingPhoto,
                isCreateEnabled: isValid,
                onPasteNote: showPasteNoteCapture,
                onImportPhoto: showPhotoPicker,
                onScanText: startLiveTextScan,
                onRecordVoice: showVoiceCapture,
                onCreate: addTask
            )
                .padding(AppStyle.Spacing.extraLarge)
        }
        .background(AppStyle.Colors.background)
        .onAppear { focusedField = .title }
        .task(id: selectedQuickCapturePhoto) {
            guard let selectedQuickCapturePhoto else { return }
            let result = await quickCapture.importPhoto(selectedQuickCapturePhoto)
            handleQuickCaptureResult(result)
            self.selectedQuickCapturePhoto = nil
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedQuickCapturePhoto,
            matching: .images
        )
        .sheet(isPresented: $showingQuickCaptureSheet) {
            QuickCaptureDraftSheet(
                text: $quickCapture.text,
                message: quickCapture.draftMessage,
                isAvailable: quickCapture.isAvailable,
                unavailableMessage: quickCapture.unavailableMessage,
                isGenerating: quickCapture.isGenerating
            ) {
                await generateTaskDraft()
            } onAddManually: {
                handleQuickCaptureResult(.applyManualText(quickCapture.text, source: .paste))
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLiveTextScanner) {
            LiveTextScannerSheet { recognizedText in
                Task {
                    let result = await quickCapture.handleRecognizedText(recognizedText, source: .scanner)
                    handleQuickCaptureResult(result)
                }
            } onError: { error in
                quickCapture.showMessage(error.localizedDescription)
            }
        }
        .sheet(isPresented: $showingVoiceCapture) {
            VoiceCaptureSheet { recognizedText in
                Task {
                    let result = await quickCapture.handleRecognizedText(recognizedText, source: .voice)
                    handleQuickCaptureResult(result)
                }
            } onError: { error in
                quickCapture.showMessage(error.localizedDescription)
            }
            .presentationDetents([.large, .large])
            .presentationDragIndicator(.visible)
        }
        .customAlert(
            isPresented: $showingWIPLimitAlert,
            iconName: "brain.head.profile",
            title: "WIP Limit Reached",
            message: "Personal Kanban recommends a WIP limit of 2 or 3 to minimize context-switching and finish tasks faster. Finish or move an active task before adding another In Progress task."
        )
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(AppStyle.Typography.body)
                .foregroundStyle(AppStyle.Colors.secondaryText)
            
            Spacer()
            
            Text("New Task")
                .font(AppStyle.Typography.headerTitle)
            
            Spacer()
            
            Button("Cancel") { dismiss() }
                .font(AppStyle.Typography.body)
                .hidden()
                .accessibilityHidden(true)
        }
        .padding(.horizontal, AppStyle.Spacing.extraLarge)
        .padding(.vertical, AppStyle.Spacing.large)
        .background(AppStyle.Materials.chrome)
        .overlay(alignment: .bottom) {
            Divider().opacity(AppStyle.Opacity.divider)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Title")
                .sectionHeaderStyle()
            
            TextField("What needs to be done?", text: $title)
                .formFieldStyle()
                .focused($focusedField, equals: .title)
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Priority")
                .sectionHeaderStyle()
            
            HStack(spacing: AppStyle.Spacing.medium) {
                ForEach(TaskPriority.allCases) { p in
                    Button {
                        withAnimation(AppStyle.Motion.snappy) { priority = p }
                    } label: {
                        VStack(spacing: AppStyle.Spacing.small) {
                            Image(systemName: priorityIcon(p))
                                .font(AppStyle.Typography.fabIcon)
                            Text(p.rawValue)
                                .font(AppStyle.Typography.priorityLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppStyle.Spacing.medium)
                        .background(priority == p ? priorityColor(p).opacity(AppStyle.Opacity.accentWashSelected) : AppStyle.Colors.surface)
                        .foregroundStyle(priority == p ? priorityColor(p) : AppStyle.Colors.secondaryText)
                        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                                .stroke(priority == p ? priorityColor(p).opacity(AppStyle.Opacity.divider) : AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
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
                .sectionHeaderStyle()

            TextField("Add context for the task", text: $description, axis: .vertical)
                .lineLimit(3...6)
                .formFieldStyle()
                .focused($focusedField, equals: .description)
        }
    }

    private var completionCriteriaSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Definition of Done")
                .sectionHeaderStyle()

            TextField("What does done look like?", text: $completionCriteria, axis: .vertical)
                .lineLimit(2...4)
                .formFieldStyle()
                .focused($focusedField, equals: .completionCriteria)

            Text("Keep it short. A compact finish check makes it easier to close the task.")
                .font(AppStyle.Typography.guidanceFooter)
                .foregroundStyle(AppStyle.Colors.secondaryText)
        }
    }

    private var statusInfo: some View {
        HStack(spacing: AppStyle.Spacing.medium) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(statusColor)
            
            Text("Adding to \(Text(status.rawValue).fontWeight(.bold)) status")
        } 
        .font(AppStyle.Typography.formFooter)
        .foregroundStyle(AppStyle.Colors.secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppStyle.Spacing.normal)
        .background(statusColor.opacity(AppStyle.Opacity.accentWashFaint))
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
    }

    private var quickCaptureMessageColor: Color {
        if quickCapture.message?.hasPrefix("Photo imported.") == true || quickCapture.message?.hasPrefix("Draft generated.") == true {
            return AppStyle.Colors.doneAccent
        }
        return quickCapture.isAvailable ? .secondary : AppStyle.Colors.warning
    }

    private func showPasteNoteCapture() {
        quickCapture.preparePasteCapture()
        showingQuickCaptureSheet = true
    }

    private func showPhotoPicker() {
        showingPhotoPicker = true
    }

    private func startLiveTextScan() {
        Task { await beginLiveTextScan() }
    }

    private func showVoiceCapture() {
        quickCapture.clearFeedback()
        showingVoiceCapture = true
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
        onTaskCreated?(task)
        dismiss()
    }

    @MainActor
    private func generateTaskDraft() async {
        let result = await quickCapture.generateDraftFromCurrentText()
        handleQuickCaptureResult(result)
    }

    @MainActor
    private func applyTaskDraft(_ draft: QuickCaptureTaskDraft, message: String) {
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
        quickCapture.markDraftApplied(message: message)
    }

    @MainActor
    private func applyManualCaptureText(_ rawText: String, source: QuickCaptureSource) {
        let cleanedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            title = cleanedText
            focusedField = .title
        } else if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            description = cleanedText
            focusedField = .description
        } else {
            let cleanedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            description = "\(cleanedDescription)\n\n\(cleanedText)"
            focusedField = .description
        }

        quickCapture.markManualTextApplied(cleanedText, source: source)
        showingQuickCaptureSheet = false
    }

    @MainActor
    private func beginLiveTextScan() async {
        quickCapture.clearFeedback()

        switch await CameraPermissionService.requestCameraAccess() {
        case .granted:
            showingLiveTextScanner = true
        case .denied:
            quickCapture.showMessage(LiveTextScannerError.cameraAccessDenied.localizedDescription)
        case .unavailable:
            quickCapture.showMessage("Camera access is unavailable right now.")
        }
    }

    @MainActor
    private func handleQuickCaptureResult(_ result: QuickCaptureCoordinatorResult) {
        switch result {
        case .none:
            break
        case .applyDraft(let draft, let message):
            applyTaskDraft(draft, message: message)
            showingQuickCaptureSheet = false
        case .applyManualText(let text, let source):
            applyManualCaptureText(text, source: source)
        case .showReviewSheet:
            showingQuickCaptureSheet = true
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
