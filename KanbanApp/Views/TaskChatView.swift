import SwiftData
import SwiftUI

enum TaskChatMessageRole: String {
    case user
    case assistant
}

struct TaskChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: TaskChatMessageRole
    let text: String
    let referencedTaskIDs: [UUID]
    let proposedActions: [TaskChatProposedAction]
    let visualizations: [TaskChatVisualization]
    let evidence: TaskChatEvidence?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: TaskChatMessageRole,
        text: String,
        referencedTaskIDs: [UUID] = [],
        proposedActions: [TaskChatProposedAction] = [],
        visualizations: [TaskChatVisualization] = [],
        evidence: TaskChatEvidence? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.referencedTaskIDs = referencedTaskIDs
        self.proposedActions = proposedActions
        self.visualizations = visualizations
        self.evidence = evidence
        self.createdAt = createdAt
    }
}

struct TaskChatView: View {
    let tasks: [TaskItem]
    @Binding var messages: [TaskChatMessage]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0
    @State private var draft = ""
    @State private var isResponding = false
    @State private var statusMessage: String?
    @State private var isConfirmingClear = false
    @State private var isConfirmingAction = false
    @State private var selectedTask: TaskItem?
    @State private var pendingAction: TaskChatProposedAction?
    @State private var consumedActionIDs: Set<UUID> = []
    @State private var recommendedPrompts: [TaskChatStarterPrompt] = []
    @State private var expandedEvidenceMessageIDs: Set<UUID> = []

    private let bottomID = "task-chat-bottom"

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isAvailable && !isResponding
    }

    private var availability: QuickCaptureAvailability {
        TaskChatService.availability
    }

    private var isAvailable: Bool {
        if case .available = availability {
            return true
        }
        return false
    }

    private var unavailableMessage: String? {
        if case .unavailable(let message) = availability {
            return message
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppStyle.Spacing.none) {
                messageList

                Divider()

                inputArea
            }
            .background(AppStyle.Colors.background)
            .navigationTitle(String(localized: "WIP Coach"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Clear"), role: .destructive) {
                        isConfirmingClear = true
                    }
                    .disabled(messages.isEmpty || isResponding)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(String(localized: "Clear chat history?"), isPresented: $isConfirmingClear, titleVisibility: .visible) {
                Button(String(localized: "Clear Chat"), role: .destructive) {
                    clearChat()
                }

                Button(String(localized: "Cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "This only clears this chat. Your tasks stay unchanged."))
            }
            .confirmationDialog(String(localized: "Apply this action?"), isPresented: $isConfirmingAction, titleVisibility: .visible) {
                Button(pendingAction?.confirmationLabel ?? String(localized: "Apply Action")) {
                    confirmPendingAction()
                }

                Button(String(localized: "Cancel"), role: .cancel) {
                    pendingAction = nil
                }
            } message: {
                Text(actionConfirmationMessage)
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                refreshRecommendedPromptsIfNeeded()
                isInputFocused = isAvailable
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppStyle.Spacing.regular) {
                    if messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(messages) { message in
                            messageRow(message)
                        }
                    }

                    if isResponding {
                        thinkingRow
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
                .padding(.vertical, AppStyle.Spacing.outerVertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: isResponding) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Spacer(minLength: AppStyle.Spacing.large)

            Image(systemName: "scope")
                .font(AppStyle.Typography.iconHero)
                .foregroundStyle(AppStyle.Colors.Status.todo)
                .frame(width: AppStyle.Shapes.iconBadgeLarge, height: AppStyle.Shapes.iconBadgeLarge)
                .background(AppStyle.Colors.Status.todo.opacity(AppStyle.Opacity.accentWash), in: Circle())

            Text(String(localized: "Ask WIP Coach"))
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)

            Text(String(localized: "Ask about flow, blockers, and cycle time."))
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppStyle.Spacing.extraLarge)

            VStack(spacing: AppStyle.Spacing.small) {
                ForEach(displayedStarterPrompts) { prompt in
                    Button {
                        Task { await sendMessage(prompt.title, requestText: prompt.requestText) }
                    } label: {
                        HStack {
                            Text(prompt.title)
                                .font(AppStyle.Typography.statusLabel)
                                .foregroundStyle(AppStyle.Colors.primaryText)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: AppStyle.Spacing.small)

                            Image(systemName: "arrow.up.circle.fill")
                                .font(AppStyle.Typography.iconMedium)
                                .foregroundStyle(isAvailable ? AppStyle.Colors.Status.todo : AppStyle.Colors.disabledControl)
                                .accessibilityHidden(true)
                        }
                        .padding(AppStyle.Spacing.compactCardPadding)
                        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
                        .background(AppStyle.Colors.surface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isAvailable || isResponding)
                }
            }

            Spacer(minLength: AppStyle.Spacing.large)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private var displayedStarterPrompts: [TaskChatStarterPrompt] {
        recommendedPrompts.isEmpty
            ? Array(TaskChatStarterPrompt.availablePrompts.prefix(3))
            : recommendedPrompts
    }

    private var thinkingRow: some View {
        HStack(alignment: .bottom, spacing: AppStyle.Spacing.small) {
            ProgressView()
                .controlSize(.small)

            Text(String(localized: "Thinking"))
                .font(AppStyle.Typography.formFooter)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Spacer(minLength: AppStyle.Spacing.extraLarge)
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func messageRow(_ message: TaskChatMessage) -> some View {
        HStack(alignment: .bottom) {
            if message.role == .user {
                Spacer(minLength: AppStyle.Spacing.extraLarge)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: AppStyle.Spacing.small) {
                messageBubble(message)

                if message.role == .assistant {
                    evidenceBlock(for: message)
                    visualizationBlocks(for: message)
                    referencedTaskChips(for: message)
                    actionCards(for: message)
                }
            }
            .frame(maxWidth: 560, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant {
                Spacer(minLength: AppStyle.Spacing.extraLarge)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .accessibilityLabel(message.text)
    }

    private func messageBubble(_ message: TaskChatMessage) -> some View {
        Text(message.text)
            .font(AppStyle.Typography.body)
            .foregroundStyle(message.role == .user ? AppStyle.Colors.inverseText : AppStyle.Colors.primaryText)
            .textSelection(.enabled)
            .padding(.horizontal, AppStyle.Spacing.normal)
            .padding(.vertical, AppStyle.Spacing.medium)
            .background(
                message.role == .user
                    ? AppStyle.Colors.Status.todo
                    : AppStyle.Colors.surface,
                in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
            )
            .overlay {
                if message.role == .assistant {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                        .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                }
            }
    }

    @ViewBuilder
    private func evidenceBlock(for message: TaskChatMessage) -> some View {
        if let evidence = message.evidence {
            TaskChatEvidenceView(
                evidence: evidence,
                tasks: resolvedEvidenceTasks(for: evidence),
                isExpanded: expandedEvidenceMessageIDs.contains(message.id),
                toggleExpansion: {
                    toggleEvidenceExpansion(for: message.id)
                },
                selectTask: { taskID in
                    if let task = tasks.first(where: { $0.id == taskID }) {
                        selectedTask = task
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func visualizationBlocks(for message: TaskChatMessage) -> some View {
        if !message.visualizations.isEmpty {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                ForEach(message.visualizations) { visualization in
                    TaskChatVisualizationView(visualization: visualization) { taskID in
                        if let task = tasks.first(where: { $0.id == taskID }) {
                            selectedTask = task
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func referencedTaskChips(for message: TaskChatMessage) -> some View {
        let referencedTasks = resolvedReferencedTasks(for: message)
        if !referencedTasks.isEmpty {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                ForEach(referencedTasks) { task in
                    Button {
                        selectedTask = task
                    } label: {
                        HStack(spacing: AppStyle.Spacing.small) {
                            Image(systemName: statusIcon(for: task.status))
                                .font(AppStyle.Typography.iconSmall)
                                .foregroundStyle(statusColor(for: task.status))
                                .frame(width: AppStyle.Spacing.iconFrameWidth)
                                .accessibilityHidden(true)

                            Text(task.title)
                                .font(AppStyle.Typography.cardTitle)
                                .foregroundStyle(AppStyle.Colors.primaryText)
                                .lineLimit(1)

                            Spacer(minLength: AppStyle.Spacing.small)

                            Image(systemName: "chevron.right")
                                .font(AppStyle.Typography.iconTiny)
                                .foregroundStyle(AppStyle.Colors.tertiaryText)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, AppStyle.Spacing.regular)
                        .padding(.vertical, AppStyle.Spacing.small)
                        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
                        .background(AppStyle.Colors.spotlightSurface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(task.title)
                    .accessibilityHint(String(localized: "Opens task details."))
                }
            }
        }
    }

    @ViewBuilder
    private func actionCards(for message: TaskChatMessage) -> some View {
        let actions = visibleActions(for: message)
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                ForEach(actions) { action in
                    Button {
                        pendingAction = action
                        isConfirmingAction = true
                    } label: {
                        HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
                            Image(systemName: actionIcon(for: action.kind))
                                .font(AppStyle.Typography.iconMedium)
                                .foregroundStyle(actionTint(for: action.kind))
                                .frame(width: AppStyle.Spacing.iconFrameWidthMedium)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                                Text(action.confirmationLabel)
                                    .font(AppStyle.Typography.statusLabelHighlighted)
                                    .foregroundStyle(AppStyle.Colors.primaryText)
                                    .lineLimit(2)

                                Text(actionSubtitle(for: action))
                                    .font(AppStyle.Typography.cardDate)
                                    .foregroundStyle(AppStyle.Colors.secondaryText)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: AppStyle.Spacing.small)

                            Image(systemName: "checkmark.circle")
                                .font(AppStyle.Typography.iconMedium)
                                .foregroundStyle(actionTint(for: action.kind))
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, AppStyle.Spacing.regular)
                        .padding(.vertical, AppStyle.Spacing.small)
                        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
                        .background(actionTint(for: action.kind).opacity(AppStyle.Opacity.accentWash), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                                .stroke(actionTint(for: action.kind).opacity(AppStyle.Opacity.accentBorderStrong), lineWidth: AppStyle.Shapes.borderWidth)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isResponding)
                    .accessibilityLabel(action.confirmationLabel)
                }
            }
        }
    }

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            if !messages.isEmpty {
                recommendedPromptStrip
            }

            if let message = statusMessage ?? unavailableMessage {
                Text(message)
                    .font(AppStyle.Typography.guidanceFooter)
                    .foregroundStyle(isAvailable ? AppStyle.Colors.secondaryText : AppStyle.Colors.warning)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppStyle.Spacing.tiny)
            }

            HStack(alignment: .bottom, spacing: AppStyle.Spacing.small) {
                TextField(String(localized: "Ask about tasks"), text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, AppStyle.Spacing.normal)
                    .padding(.vertical, AppStyle.Spacing.medium)
                    .background(AppStyle.Colors.surface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                            .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                    }
                    .focused($isInputFocused)
                    .disabled(!isAvailable || isResponding)
                    .submitLabel(.send)
                    .onSubmit {
                        guard canSend else { return }
                        Task { await sendMessage() }
                    }

                Button {
                    Task { await sendMessage() }
                } label: {
                    if isResponding {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: AppStyle.Shapes.minimumTapTarget, height: AppStyle.Shapes.minimumTapTarget)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(AppStyle.Typography.iconHero)
                            .frame(width: AppStyle.Shapes.minimumTapTarget, height: AppStyle.Shapes.minimumTapTarget)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(canSend ? AppStyle.Colors.Status.todo : AppStyle.Colors.disabledControl)
                .disabled(!canSend)
                .accessibilityLabel(String(localized: "Send"))
            }
        }
        .padding(.horizontal, AppStyle.Spacing.normal)
        .padding(.top, AppStyle.Spacing.medium)
        .padding(.bottom, AppStyle.Spacing.normal)
        .background(AppStyle.Colors.background)
    }

    private var recommendedPromptStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppStyle.Spacing.small) {
                ForEach(displayedStarterPrompts) { prompt in
                    Button {
                        Task { await sendMessage(prompt.title, requestText: prompt.requestText) }
                    } label: {
                        HStack(spacing: AppStyle.Spacing.small) {
                            Text(prompt.title)
                                .font(AppStyle.Typography.statusLabel)
                                .foregroundStyle(AppStyle.Colors.primaryText)
                                .lineLimit(3)
                                .minimumScaleFactor(0.85)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: AppStyle.Spacing.tiny)

                            Image(systemName: "arrow.up.circle.fill")
                                .font(AppStyle.Typography.iconMedium)
                                .foregroundStyle(isAvailable ? AppStyle.Colors.Status.todo : AppStyle.Colors.disabledControl)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, AppStyle.Spacing.regular)
                        .padding(.vertical, AppStyle.Spacing.small)
                        .frame(width: 260, alignment: .leading)
                        .frame(minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
                        .background(AppStyle.Colors.surface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!isAvailable || isResponding)
                }
            }
            .padding(.horizontal, AppStyle.Spacing.tiny)
        }
    }

    @MainActor
    private func sendMessage(_ explicitText: String? = nil, requestText: String? = nil) async {
        let rawText = explicitText ?? draft
        let displayedQuestion = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let question = (requestText ?? rawText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !displayedQuestion.isEmpty && !question.isEmpty else { return }
        guard !isResponding else { return }

        guard isAvailable else {
            statusMessage = unavailableMessage
            return
        }

        let previousTurns = messages
            .suffix(8)
            .map { TaskChatTurn(role: $0.role.rawValue, content: $0.text) }

        messages.append(TaskChatMessage(role: .user, text: displayedQuestion))
        if explicitText == nil {
            draft = ""
        }
        statusMessage = nil
        isResponding = true
        isInputFocused = false

        defer {
            isResponding = false
            isInputFocused = true
        }

        do {
            let request = TaskChatRequest(
                question: question,
                previousTurns: Array(previousTurns),
                tasks: tasks
            )
            let response = try await TaskChatService.respond(to: request)
            let answer = response.answer.isEmpty
                ? String(localized: "I could not find enough task data to answer that.")
                : response.answer
            messages.append(
                TaskChatMessage(
                    role: .assistant,
                    text: answer,
                    referencedTaskIDs: response.referencedTaskIDs,
                    proposedActions: response.proposedActions,
                    visualizations: response.visualizations,
                    evidence: response.evidence
                )
            )
        } catch {
            messages.append(
                TaskChatMessage(
                    role: .assistant,
                    text: String(localized: "I could not answer from the on-device model right now. Try again in a moment.")
                )
            )
        }
    }

    private func refreshRecommendedPromptsIfNeeded() {
        guard recommendedPrompts.isEmpty else { return }
        recommendedPrompts = Array(TaskChatStarterPrompt.availablePrompts.shuffled().prefix(3))
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(AppStyle.Motion.snappy) {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }

    private func clearChat() {
        messages.removeAll()
        statusMessage = nil
        consumedActionIDs.removeAll()
        expandedEvidenceMessageIDs.removeAll()
        pendingAction = nil
        isConfirmingAction = false
        isInputFocused = isAvailable
    }

    private func resolvedReferencedTasks(for message: TaskChatMessage) -> [TaskItem] {
        message.referencedTaskIDs.compactMap { id in
            tasks.first { $0.id == id }
        }
    }

    private func resolvedEvidenceTasks(for evidence: TaskChatEvidence) -> [TaskItem] {
        evidence.includedTaskIDs.compactMap { id in
            tasks.first { $0.id == id }
        }
    }

    private func toggleEvidenceExpansion(for messageID: UUID) {
        if expandedEvidenceMessageIDs.contains(messageID) {
            expandedEvidenceMessageIDs.remove(messageID)
        } else {
            expandedEvidenceMessageIDs.insert(messageID)
        }
    }

    private func visibleActions(for message: TaskChatMessage) -> [TaskChatProposedAction] {
        guard shouldShowActions(for: message) else { return [] }
        return message.proposedActions.filter { action in
            action.kind != .addNextAction && !consumedActionIDs.contains(action.id) && resolvedTask(for: action) != nil
        }
    }

    private func shouldShowActions(for message: TaskChatMessage) -> Bool {
        guard message.role == .assistant else { return false }
        return messages.last(where: { $0.role == .assistant })?.id == message.id
    }

    private func resolvedTask(for action: TaskChatProposedAction) -> TaskItem? {
        tasks.first { $0.id == action.taskID }
    }

    private var actionConfirmationMessage: String {
        guard let pendingAction else {
            return String(localized: "Your tasks stay unchanged until you confirm.")
        }
        let taskTitle = resolvedTask(for: pendingAction)?.title ?? pendingAction.taskTitle
        switch pendingAction.kind {
        case .openTask:
            return String(localized: "This will open \"\(taskTitle)\" for review.")
        case .addNextAction:
            return String(localized: "This will add a next action to \"\(taskTitle)\".")
        case .markBlocked:
            return String(localized: "This will mark \"\(taskTitle)\" as blocked.")
        case .markActive:
            return String(localized: "This will mark \"\(taskTitle)\" as active.")
        case .moveToTodo:
            return String(localized: "This will move \"\(taskTitle)\" to To Do.")
        case .moveToInProgress:
            return String(localized: "This will move \"\(taskTitle)\" to In Progress.")
        case .markDone:
            return String(localized: "This will mark \"\(taskTitle)\" Done.")
        case .archiveDoneTask:
            return String(localized: "This will archive \"\(taskTitle)\".")
        }
    }

    private func actionSubtitle(for action: TaskChatProposedAction) -> String {
        let taskTitle = resolvedTask(for: action)?.title ?? action.taskTitle
        switch action.kind {
        case .addNextAction where !action.payload.isEmpty:
            return action.payload
        default:
            return taskTitle
        }
    }

    private func actionIcon(for kind: TaskChatActionKind) -> String {
        switch kind {
        case .openTask:
            return "arrow.up.forward.app"
        case .addNextAction:
            return "bolt.fill"
        case .markBlocked:
            return "pause.circle.fill"
        case .markActive:
            return "play.circle.fill"
        case .moveToTodo:
            return "arrow.left.circle"
        case .moveToInProgress:
            return "arrow.right.circle"
        case .markDone:
            return "checkmark.circle.fill"
        case .archiveDoneTask:
            return "archivebox.fill"
        }
    }

    private func actionTint(for kind: TaskChatActionKind) -> Color {
        switch kind {
        case .openTask, .addNextAction:
            return AppStyle.Colors.Status.todo
        case .markBlocked:
            return AppStyle.Colors.blocked
        case .markActive, .moveToInProgress:
            return AppStyle.Colors.Status.inProgress
        case .moveToTodo:
            return AppStyle.Colors.Status.todo
        case .markDone, .archiveDoneTask:
            return AppStyle.Colors.Status.done
        }
    }

    private func statusIcon(for status: TaskStatus) -> String {
        switch status {
        case .todo:
            return "circle"
        case .inProgress:
            return "clock.fill"
        case .done:
            return "checkmark.circle.fill"
        }
    }

    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo:
            return AppStyle.Colors.Status.todo
        case .inProgress:
            return AppStyle.Colors.Status.inProgress
        case .done:
            return AppStyle.Colors.Status.done
        }
    }

    private func confirmPendingAction() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        consumedActionIDs.insert(action.id)

        guard let task = resolvedTask(for: action) else {
            appendAssistantMessage(String(localized: "I could not find that task anymore."))
            return
        }

        let result = apply(action, to: task)
        appendAssistantMessage(result)
    }

    private func apply(_ action: TaskChatProposedAction, to task: TaskItem) -> String {
        switch action.kind {
        case .openTask:
            selectedTask = task
            return String(localized: "Opened \(task.title).")
        case .addNextAction:
            return addNextAction(action.payload, to: task)
        case .markBlocked:
            return markBlocked(true, task: task)
        case .markActive:
            return markBlocked(false, task: task)
        case .moveToTodo:
            return move(task, to: .todo)
        case .moveToInProgress:
            return move(task, to: .inProgress)
        case .markDone:
            return move(task, to: .done)
        case .archiveDoneTask:
            return archiveDoneTask(task)
        }
    }

    private func appendAssistantMessage(_ text: String) {
        messages.append(TaskChatMessage(role: .assistant, text: text))
    }

    private func addNextAction(_ rawNextAction: String, to task: TaskItem) -> String {
        let nextAction = rawNextAction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nextAction.isEmpty else {
            return String(localized: "I could not add that next action because the proposal was empty.")
        }

        let suggestionLine = String(localized: "Next action: \(nextAction)")
        let trimmedDescription = task.desc.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedDescription.contains(suggestionLine) {
            return String(localized: "That next action is already on \(task.title).")
        }

        if trimmedDescription.isEmpty {
            task.desc = suggestionLine
        } else {
            task.desc = "\(trimmedDescription)\n\n\(suggestionLine)"
        }

        task.updatedAt = Date()
        try? modelContext.save()
        return String(localized: "Done. I added a next action to \(task.title).")
    }

    private func markBlocked(_ isBlocked: Bool, task: TaskItem) -> String {
        guard task.status == .inProgress else {
            return String(localized: "I can only update blocked state for In Progress tasks.")
        }

        if task.isBlocked == isBlocked {
            return isBlocked
                ? String(localized: "\(task.title) is already marked blocked.")
                : String(localized: "\(task.title) is already active.")
        }

        task.isBlocked = isBlocked
        task.updatedAt = Date()
        try? modelContext.save()

        return isBlocked
            ? String(localized: "Done. I marked \(task.title) as blocked.")
            : String(localized: "Done. I marked \(task.title) as active.")
    }

    private func move(_ task: TaskItem, to status: TaskStatus) -> String {
        guard task.status != status else {
            return String(localized: "\(task.title) is already in \(status.localizedName).")
        }

        if status == .inProgress && task.status != .inProgress && isWIPLimitReached(excluding: task) {
            wipLimitHitCount += 1
            return String(localized: "I did not move \(task.title) because your In Progress lane is at the WIP limit.")
        }

        let previousStatus = task.status
        task.order = nextOrder(for: status, excluding: task)
        task.status = status
        task.updatedAt = Date()
        reorderTasks(in: previousStatus)
        reorderTasks(in: status)
        try? modelContext.save()

        return String(localized: "Done. I moved \(task.title) to \(status.localizedName).")
    }

    private func archiveDoneTask(_ task: TaskItem) -> String {
        guard task.status == .done else {
            return String(localized: "I can only archive Done tasks.")
        }
        guard !task.isArchived else {
            return String(localized: "\(task.title) is already archived.")
        }

        task.archive()
        reorderTasks(in: .done)
        try? modelContext.save()
        return String(localized: "Done. I archived \(task.title).")
    }

    private func isWIPLimitReached(excluding task: TaskItem) -> Bool {
        guard isFocusGuardEnabled else { return false }
        let activeCount = allPersistedTasks()
            .filter { $0.status == .inProgress && !$0.isArchived && $0.id != task.id }
            .count
        return activeCount >= max(maxActiveTasks, 1)
    }

    private func nextOrder(for status: TaskStatus, excluding task: TaskItem) -> Int {
        allPersistedTasks()
            .filter { $0.status == status && !$0.isArchived && $0.id != task.id }
            .count
    }

    private func reorderTasks(in status: TaskStatus) {
        let sortedTasks = allPersistedTasks()
            .filter { $0.status == status && !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                if lhs.order != rhs.order {
                    return lhs.order < rhs.order
                }
                return lhs.createdAt < rhs.createdAt
            }

        for (index, item) in sortedTasks.enumerated() {
            item.order = index
        }
    }

    private func allPersistedTasks() -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>()
        return (try? modelContext.fetch(descriptor)) ?? tasks
    }
}

#Preview("Task Chat") {
    TaskChatPreview()
        .modelContainer(for: TaskItem.self, inMemory: true)
}

private struct TaskChatPreview: View {
    @State private var messages = [
        TaskChatMessage(role: .user, text: "How many tasks did I close this month?"),
        TaskChatMessage(
            role: .assistant,
            text: "You closed 3 tasks this month.",
            visualizations: [
                TaskChatVisualization(
                    kind: .statusBreakdown,
                    title: String(localized: "Status Breakdown"),
                    subtitle: String(localized: "6 visible tasks, 2 archived completed"),
                    metricCards: [
                        TaskChatMetricCard(label: String(localized: "Visible"), value: "6", systemImage: "rectangle.grid.2x2", tint: .neutral),
                        TaskChatMetricCard(label: String(localized: "Blocked"), value: "1", systemImage: "pause.circle.fill", tint: .blocked)
                    ],
                    bars: [
                        TaskChatBar(label: TaskStatus.todo.localizedName, value: 2, displayValue: "2", tint: .todo),
                        TaskChatBar(label: TaskStatus.inProgress.localizedName, value: 3, displayValue: "3", tint: .inProgress),
                        TaskChatBar(label: TaskStatus.done.localizedName, value: 1, displayValue: "1", tint: .done)
                    ],
                    table: TaskChatTable(
                        columns: [String(localized: "Task"), String(localized: "Age"), String(localized: "Priority")],
                        rows: [
                            TaskChatTableRow(values: [String(localized: "Review onboarding flow"), String(localized: "2 days"), TaskPriority.high.localizedName])
                        ]
                    )
                )
            ]
        )
    ]

    var body: some View {
        TaskChatView(tasks: WIPPreviewData.overloaded, messages: $messages)
    }
}

private struct TaskChatEvidenceView: View {
    let evidence: TaskChatEvidence
    let tasks: [TaskItem]
    let isExpanded: Bool
    let toggleExpansion: () -> Void
    let selectTask: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            header

            if !evidence.rows.isEmpty {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                    ForEach(evidence.rows) { row in
                        TaskChatEvidenceRowView(row: row)
                    }
                }
            }

            if !tasks.isEmpty {
                Button {
                    toggleExpansion()
                } label: {
                    HStack(spacing: AppStyle.Spacing.small) {
                        Label(
                            isExpanded ? String(localized: "Hide tasks") : String(localized: "View tasks"),
                            systemImage: isExpanded ? "chevron.up.circle.fill" : "list.bullet.rectangle"
                        )
                        .font(AppStyle.Typography.statusLabel)

                        Spacer(minLength: AppStyle.Spacing.small)

                        Text(tasks.count.formatted())
                            .font(AppStyle.Typography.cardDate)
                            .monospacedDigit()
                            .foregroundStyle(AppStyle.Colors.secondaryText)
                    }
                    .foregroundStyle(AppStyle.Colors.Status.todo)
                    .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            TaskChatEvidenceTaskRow(task: task, selectTask: selectTask)

                            if index < tasks.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.Colors.spotlightSurface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(spacing: AppStyle.Spacing.small) {
            Image(systemName: "checkmark.seal.fill")
                .font(AppStyle.Typography.iconSmall)
                .foregroundStyle(AppStyle.Colors.Status.done)
                .accessibilityHidden(true)

            Text(String(localized: "Answer sources"))
                .font(AppStyle.Typography.statusLabelHighlighted)
                .foregroundStyle(AppStyle.Colors.primaryText)
        }
    }
}

private struct TaskChatEvidenceRowView: View {
    let row: TaskChatEvidenceRow

    var body: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
            Text(row.label)
                .font(AppStyle.Typography.cardDate)
                .foregroundStyle(AppStyle.Colors.tertiaryText)
                .frame(width: 104, alignment: .leading)
                .lineLimit(2)

            Text(row.value)
                .font(AppStyle.Typography.cardDate)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TaskChatEvidenceTaskRow: View {
    let task: TaskItem
    let selectTask: (UUID) -> Void

    var body: some View {
        Button {
            selectTask(task.id)
        } label: {
            HStack(spacing: AppStyle.Spacing.small) {
                Image(systemName: statusIcon)
                    .font(AppStyle.Typography.iconSmall)
                    .foregroundStyle(statusColor)
                    .frame(width: AppStyle.Spacing.iconFrameWidth)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppStyle.Spacing.micro) {
                    Text(task.title)
                        .font(AppStyle.Typography.cardTitle)
                        .foregroundStyle(AppStyle.Colors.primaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(task.status.localizedName) - \(task.priority.localizedName)")
                        .font(AppStyle.Typography.cardDate)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: AppStyle.Spacing.small)

                Image(systemName: "chevron.right")
                    .font(AppStyle.Typography.iconTiny)
                    .foregroundStyle(AppStyle.Colors.tertiaryText)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, AppStyle.Spacing.small)
            .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.title)
        .accessibilityHint(String(localized: "Opens task details."))
    }

    private var statusIcon: String {
        switch task.status {
        case .todo:
            return "circle"
        case .inProgress:
            return task.isBlocked ? "pause.circle.fill" : "clock.fill"
        case .done:
            return "checkmark.circle.fill"
        }
    }

    private var statusColor: Color {
        if task.status == .inProgress && task.isBlocked {
            return AppStyle.Colors.blocked
        }

        switch task.status {
        case .todo:
            return AppStyle.Colors.Status.todo
        case .inProgress:
            return AppStyle.Colors.Status.inProgress
        case .done:
            return AppStyle.Colors.Status.done
        }
    }
}

private struct TaskChatVisualizationView: View {
    let visualization: TaskChatVisualization
    let selectTask: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            header

            if !visualization.metricCards.isEmpty {
                TaskChatMetricCardsView(cards: visualization.metricCards)
            }

            if !visualization.bars.isEmpty {
                TaskChatBarChartView(bars: visualization.bars)
            }

            if let table = visualization.table {
                TaskChatTableView(table: table, selectTask: selectTask)
            }
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.Colors.surface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
            Image(systemName: iconName)
                .font(AppStyle.Typography.iconMedium)
                .foregroundStyle(visualizationTintColor(primaryTint))
                .frame(width: AppStyle.Spacing.iconFrameWidthMedium)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                Text(visualization.title)
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .lineLimit(2)

                Text(visualization.subtitle)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var iconName: String {
        switch visualization.kind {
        case .statusBreakdown, .priorityBreakdown:
            return "chart.bar.xaxis"
        case .activeAging:
            return "clock.badge"
        case .completedThisMonth:
            return "calendar.badge.checkmark"
        case .slowestClosed:
            return "hourglass"
        case .blockedTasks:
            return "pause.circle.fill"
        case .throughputTrend:
            return "chart.line.uptrend.xyaxis"
        case .closeTimeTrend:
            return "gauge.with.dots.needle.33percent"
        case .weekComparison, .monthComparison:
            return "arrow.left.arrow.right.circle.fill"
        case .priorityCloseTime:
            return "flag.checkered"
        }
    }

    private var primaryTint: TaskChatVisualizationTint {
        visualization.metricCards.first?.tint ?? visualization.bars.first?.tint ?? .neutral
    }
}

private struct TaskChatMetricCardsView: View {
    let cards: [TaskChatMetricCard]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: AppStyle.Spacing.small)]
            : [
                GridItem(.flexible(), spacing: AppStyle.Spacing.small),
                GridItem(.flexible(), spacing: AppStyle.Spacing.small)
            ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppStyle.Spacing.small) {
            ForEach(cards) { card in
                TaskChatMetricCardView(card: card)
            }
        }
    }
}

private struct TaskChatMetricCardView: View {
    let card: TaskChatMetricCard

    private var tint: Color {
        visualizationTintColor(card.tint)
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
            Image(systemName: card.systemImage)
                .font(AppStyle.Typography.iconSmall)
                .foregroundStyle(tint)
                .frame(width: AppStyle.Spacing.iconFrameWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.micro) {
                Text(card.value)
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(AppStyle.Typography.minimumScaleFactor)

                Text(card.label)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppStyle.Spacing.tiny)
        }
        .padding(.horizontal, AppStyle.Spacing.small)
        .padding(.vertical, AppStyle.Spacing.small)
        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
        .background(tint.opacity(AppStyle.Opacity.accentWash), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
    }
}

private struct TaskChatBarChartView: View {
    let bars: [TaskChatBar]

    private var maxValue: Double {
        max(bars.map(\.value).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            ForEach(bars) { bar in
                TaskChatBarRow(bar: bar, maxValue: maxValue)
            }
        }
    }
}

private struct TaskChatBarRow: View {
    let bar: TaskChatBar
    let maxValue: Double

    private var tint: Color {
        visualizationTintColor(bar.tint)
    }

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return min(max(bar.value / maxValue, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            HStack(alignment: .firstTextBaseline, spacing: AppStyle.Spacing.small) {
                Text(bar.label)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .lineLimit(1)

                Spacer(minLength: AppStyle.Spacing.small)

                Text(bar.displayValue)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .monospacedDigit()
                    .lineLimit(1)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppStyle.Colors.track.opacity(AppStyle.Opacity.subtleTrack))

                    Capsule()
                        .fill(tint)
                        .frame(width: max(AppStyle.Shapes.minBarWidth, proxy.size.width * fraction))
                }
            }
            .frame(height: AppStyle.Shapes.progressBarHeight)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(bar.label), \(bar.displayValue)")
    }
}

private struct TaskChatTableView: View {
    let table: TaskChatTable
    let selectTask: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            if table.rows.isEmpty {
                Text(String(localized: "No rows to show"))
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .padding(.vertical, AppStyle.Spacing.small)
            } else {
                ForEach(Array(table.rows.enumerated()), id: \.element.id) { index, row in
                    TaskChatTableRowView(
                        columns: table.columns,
                        row: row,
                        selectTask: selectTask
                    )

                    if index < table.rows.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct TaskChatTableRowView: View {
    let columns: [String]
    let row: TaskChatTableRow
    let selectTask: (UUID) -> Void

    var body: some View {
        Group {
            if let taskID = row.taskID {
                Button {
                    selectTask(taskID)
                } label: {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "Opens task details."))
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.small) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                Text(row.values.first ?? String(localized: "Item"))
                    .font(AppStyle.Typography.cardTitle)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !detailPairs.isEmpty {
                    HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
                        ForEach(detailPairs, id: \.label) { pair in
                            VStack(alignment: .leading, spacing: AppStyle.Spacing.micro) {
                                Text(pair.label)
                                    .font(AppStyle.Typography.formFooter)
                                    .foregroundStyle(AppStyle.Colors.tertiaryText)
                                    .lineLimit(1)

                                Text(pair.value)
                                    .font(AppStyle.Typography.cardDate)
                                    .foregroundStyle(AppStyle.Colors.secondaryText)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            if row.taskID != nil {
                Image(systemName: "chevron.right")
                    .font(AppStyle.Typography.iconTiny)
                    .foregroundStyle(AppStyle.Colors.tertiaryText)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, AppStyle.Spacing.small)
        .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var detailPairs: [(label: String, value: String)] {
        guard row.values.count > 1 else { return [] }
        return row.values.dropFirst().enumerated().map { offset, value in
            let columnIndex = offset + 1
            return (
                label: columnIndex < columns.count ? columns[columnIndex] : String(localized: "Value"),
                value: value
            )
        }
    }
}

private func visualizationTintColor(_ tint: TaskChatVisualizationTint) -> Color {
    switch tint {
    case .todo:
        return AppStyle.Colors.Status.todo
    case .inProgress:
        return AppStyle.Colors.Status.inProgress
    case .done:
        return AppStyle.Colors.Status.done
    case .high:
        return AppStyle.Colors.warning
    case .medium:
        return AppStyle.Colors.Status.inProgress
    case .low:
        return AppStyle.Colors.Status.todo
    case .blocked:
        return AppStyle.Colors.blocked
    case .neutral:
        return AppStyle.Colors.secondaryText
    }
}
