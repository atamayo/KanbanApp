import SwiftData
import PhotosUI
import SwiftUI
import AVFoundation

struct AddTaskView: View {
    let status: TaskStatus
    var onTaskCreated: ((TaskItem) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var quickCaptureText = ""
    @State private var title = ""
    @State private var description = ""
    @State private var completionCriteria = ""
    @State private var priority: TaskPriority = .medium
    @State private var selectedQuickCapturePhoto: PhotosPickerItem?
    @State private var isGeneratingQuickCapture = false
    @State private var isImportingQuickCapturePhoto = false
    @State private var quickCaptureMessage: String?
    @State private var quickCaptureDraftMessage: String?
    @State private var showingWIPLimitAlert = false
    @State private var showingQuickCaptureSheet = false
    @State private var showingPhotoPicker = false
    @State private var showingLiveTextScanner = false
    @State private var showingVoiceCapture = false
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
            
            bottomActionBar
                .padding(AppStyle.Spacing.extraLarge)
        }
        .background(AppStyle.Colors.background)
        .onAppear { focusedField = .title }
        .task(id: selectedQuickCapturePhoto) {
            guard let selectedQuickCapturePhoto else { return }
            await importQuickCapturePhoto(selectedQuickCapturePhoto)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedQuickCapturePhoto,
            matching: .images
        )
        .sheet(isPresented: $showingQuickCaptureSheet) {
            QuickCaptureDraftSheet(
                text: $quickCaptureText,
                message: quickCaptureDraftMessage,
                isAvailable: isQuickCaptureAvailable,
                unavailableMessage: quickCaptureUnavailableMessage,
                isGenerating: isGeneratingQuickCapture
            ) {
                await generateTaskDraft()
            } onAddManually: {
                applyManualCaptureText(quickCaptureText, source: .paste)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLiveTextScanner) {
            LiveTextScannerSheet { recognizedText in
                Task { await handleRecognizedQuickCaptureText(recognizedText, source: .scanner) }
            } onError: { error in
                quickCaptureMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $showingVoiceCapture) {
            VoiceCaptureSheet { recognizedText in
                Task { await handleRecognizedQuickCaptureText(recognizedText, source: .voice) }
            } onError: { error in
                quickCaptureMessage = error.localizedDescription
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

    private var bottomActionBar: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            if isImportingQuickCapturePhoto {
                HStack(spacing: AppStyle.Spacing.small) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Extracting text from image…")
                        .font(AppStyle.Typography.guidanceFooter)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                }
            } else if let quickCaptureMessage {
                Text(quickCaptureMessage)
                    .font(AppStyle.Typography.guidanceFooter)
                    .foregroundStyle(quickCaptureMessageColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: AppStyle.Spacing.medium) {
                captureMenu
                createButton
            }
        }
    }

    private var captureMenu: some View {
        Menu {
            Button {
                quickCaptureDraftMessage = isQuickCaptureAvailable ? nil : QuickCaptureSource.paste.reviewMessage
                showingQuickCaptureSheet = true
            } label: {
                Label("Paste Note", systemImage: "square.and.pencil")
            }

            Button {
                showingPhotoPicker = true
            } label: {
                Label("Import Photo", systemImage: "photo.on.rectangle.angled")
            }

            Button {
                Task { await beginLiveTextScan() }
            } label: {
                Label("Scan Text", systemImage: "camera.viewfinder")
            }

            Button {
                quickCaptureMessage = nil
                showingVoiceCapture = true
            } label: {
                Label("Record Voice", systemImage: "mic.fill")
            }
        } label: {
            HStack(spacing: AppStyle.Spacing.small) {
                Image(systemName: "wand.and.stars")
                Text("Capture")
            }
            .font(AppStyle.Typography.buttonLabel)
            .frame(height: AppStyle.Shapes.fabSize)
            .padding(.horizontal, AppStyle.Spacing.normal)
            .frame(minWidth: AppStyle.Shapes.formControlMinWidth)
        }
        .buttonStyle(.glass)
        .disabled(isGeneratingQuickCapture || isImportingQuickCapturePhoto)
    }

    private var createButton: some View {
        Button {
            addTask()
        } label: {
            HStack(spacing: AppStyle.Spacing.small) {
                Image(systemName: "text.badge.plus")
                    .font(AppStyle.Typography.buttonLabel)

                Text("Create Task")
                    .font(AppStyle.Typography.buttonLabel)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppStyle.Shapes.fabSize)
        }
        .tint(isValid ? AppStyle.Colors.Status.todo : AppStyle.Colors.disabledControl)
        .buttonStyle(.glass)
        .disabled(!isValid)
    }

    private var quickCaptureAvailability: QuickCaptureAvailability {
        QuickCaptureTaskGenerator.availability
    }

    private var quickCaptureMessageColor: Color {
        if quickCaptureMessage?.hasPrefix("Photo imported.") == true || quickCaptureMessage?.hasPrefix("Draft generated.") == true {
            return AppStyle.Colors.doneAccent
        }
        return isQuickCaptureAvailable ? .secondary : AppStyle.Colors.warning
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
        onTaskCreated?(task)
        dismiss()
    }

    @MainActor
    private func generateTaskDraft() async {
        let cleanedText = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }
        guard isQuickCaptureAvailable else {
            quickCaptureDraftMessage = quickCaptureUnavailableMessage
            return
        }

        isGeneratingQuickCapture = true
        quickCaptureDraftMessage = nil

        defer { isGeneratingQuickCapture = false }

        do {
            let draft = try await QuickCaptureTaskGenerator.generate(from: cleanedText)
            applyTaskDraft(draft, message: "Draft generated. Review and adjust before creating the task.")
            showingQuickCaptureSheet = false
        } catch {
            quickCaptureDraftMessage = "Quick Capture AI couldn’t generate a draft right now. Try shortening the note and retry."
        }
    }

    @MainActor
    private func importQuickCapturePhoto(_ item: PhotosPickerItem) async {
        isImportingQuickCapturePhoto = true
        quickCaptureMessage = nil
        quickCaptureDraftMessage = nil

        defer {
            isImportingQuickCapturePhoto = false
            selectedQuickCapturePhoto = nil
        }

        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                quickCaptureMessage = "The selected image could not be loaded."
                return
            }

            let extractedText = try await ImageTextExtractionService.extractText(from: imageData)
            await handleRecognizedQuickCaptureText(extractedText, source: .photo)
        } catch let error as ImageTextExtractionError {
            quickCaptureMessage = error.localizedDescription
        } catch {
            quickCaptureMessage = "The image text was extracted, but the AI draft couldn’t be generated right now. Review it and generate again."
            showingQuickCaptureSheet = true
        }
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
        quickCaptureMessage = message
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

        quickCaptureText = cleanedText
        quickCaptureDraftMessage = nil
        quickCaptureMessage = source.manualAppliedMessage
        showingQuickCaptureSheet = false
    }

    @MainActor
    private func beginLiveTextScan() async {
        quickCaptureMessage = nil
        quickCaptureDraftMessage = nil

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingLiveTextScanner = true
        case .notDetermined:
            let granted = await requestCameraAccess()
            if granted {
                showingLiveTextScanner = true
            } else {
                quickCaptureMessage = LiveTextScannerError.cameraAccessDenied.localizedDescription
            }
        case .denied, .restricted:
            quickCaptureMessage = LiveTextScannerError.cameraAccessDenied.localizedDescription
        @unknown default:
            quickCaptureMessage = "Camera access is unavailable right now."
        }
    }

    @MainActor
    private func handleRecognizedQuickCaptureText(_ recognizedText: String, source: QuickCaptureSource) async {
        let cleanedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else {
            quickCaptureMessage = LiveTextScannerError.noTextFound.localizedDescription
            return
        }

        quickCaptureText = cleanedText
        quickCaptureDraftMessage = source.reviewMessage

        guard isQuickCaptureAvailable else {
            applyManualCaptureText(cleanedText, source: source)
            return
        }

        isGeneratingQuickCapture = true
        defer { isGeneratingQuickCapture = false }

        do {
            let draft = try await QuickCaptureTaskGenerator.generate(from: cleanedText)
            applyTaskDraft(draft, message: source.successMessage)
        } catch {
            showingQuickCaptureSheet = true
            quickCaptureMessage = source.generationFailureMessage
        }
    }

    private func requestCameraAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
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

private enum QuickCaptureSource {
    case paste
    case photo
    case scanner
    case voice

    var reviewMessage: String {
        switch self {
        case .paste:
            return "Apple Intelligence is unavailable, so paste text here and add it to the task manually."
        case .photo:
            return "Photo imported. Review the extracted text or generate a draft."
        case .scanner:
            return "Text captured. Review the extracted text or generate a draft."
        case .voice:
            return "Voice captured. Review the transcript or generate a draft."
        }
    }

    var manualAppliedMessage: String {
        switch self {
        case .paste:
            return "Text added. Apple Intelligence is unavailable, so review it manually before creating the task."
        case .photo:
            return "Photo imported. Apple Intelligence is unavailable, so the text was added for manual review."
        case .scanner:
            return "Text captured. Apple Intelligence is unavailable, so the text was added for manual review."
        case .voice:
            return "Voice captured. Apple Intelligence is unavailable, so the transcript was added for manual review."
        }
    }

    var successMessage: String {
        switch self {
        case .paste:
            return "Draft generated. Review and adjust before creating the task."
        case .photo:
            return "Photo imported. Draft generated from the extracted text."
        case .scanner:
            return "Text captured. Draft generated from the camera scan."
        case .voice:
            return "Voice captured. Draft generated from your dictation."
        }
    }

    var generationFailureMessage: String {
        switch self {
        case .paste:
            return "Quick Capture AI couldn’t generate a draft right now. Review the text and try again."
        case .photo:
            return "The image text was extracted, but the AI draft couldn’t be generated right now. Review it and generate again."
        case .scanner:
            return "The text was captured, but the AI draft couldn’t be generated right now. Review it and generate again."
        case .voice:
            return "The voice transcript was captured, but the AI draft couldn’t be generated right now. Review it and generate again."
        }
    }
}

private struct QuickCaptureDraftSheet: View {
    @Binding var text: String
    let message: String?
    let isAvailable: Bool
    let unavailableMessage: String?
    let isGenerating: Bool
    let onGenerate: @MainActor () async -> Void
    let onAddManually: @MainActor () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFocused: Bool

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canPerformPrimaryAction: Bool {
        hasText && !isGenerating
    }

    private var headerDescription: String {
        if isAvailable {
            return "Paste a note, email, or rough thought and turn it into a clean task draft."
        }
        return "Paste a note, email, or rough thought and add it to the task for manual review."
    }

    private var primaryActionTitle: String {
        isAvailable ? "Generate Draft" : "Add Text"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                    Text("Quick Capture")
                        .font(AppStyle.Typography.compactHeaderTitle)

                    Text(headerDescription)
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                }

                TextField("Paste a note or messy thought…", text: $text, axis: .vertical)
                    .lineLimit(8...14)
                    .formFieldStyle()
                    .focused($isTextFocused)

                if let message {
                    Text(message)
                        .font(AppStyle.Typography.guidanceFooter)
                        .foregroundStyle(message.hasPrefix("Draft generated.") ? AppStyle.Colors.doneAccent : AppStyle.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else if !isAvailable, let unavailableMessage {
                    Text(unavailableMessage)
                        .font(AppStyle.Typography.guidanceFooter)
                        .foregroundStyle(AppStyle.Colors.warning)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppStyle.Spacing.none)
            }
            .padding(AppStyle.Spacing.extraLarge)
            .background(AppStyle.Colors.background)
            .navigationTitle("Paste Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if isAvailable {
                            Task { await onGenerate() }
                        } else {
                            onAddManually()
                            dismiss()
                        }
                    } label: {
                        if isGenerating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(primaryActionTitle)
                        }
                    }
                    .disabled(!canPerformPrimaryAction)
                }
            }
            .onAppear {
                isTextFocused = true
            }
        }
    }
}
