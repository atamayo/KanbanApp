import SwiftUI

struct AddTaskActionBar: View {
    let isImportingQuickCapturePhoto: Bool
    let quickCaptureMessage: String?
    let quickCaptureMessageColor: Color
    let isQuickCaptureBusy: Bool
    let isCreateEnabled: Bool
    let onPasteNote: () -> Void
    let onImportPhoto: () -> Void
    let onScanText: () -> Void
    let onRecordVoice: () -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            feedbackMessage

            HStack(spacing: AppStyle.Spacing.medium) {
                captureMenu
                createButton
            }
        }
    }

    @ViewBuilder
    private var feedbackMessage: some View {
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
    }

    private var captureMenu: some View {
        Menu {
            Button {
                onPasteNote()
            } label: {
                Label("Paste Note", systemImage: "square.and.pencil")
            }

            Button {
                onImportPhoto()
            } label: {
                Label("Import Photo", systemImage: "photo.on.rectangle.angled")
            }

            Button {
                onScanText()
            } label: {
                Label("Scan Text", systemImage: "camera.viewfinder")
            }

            Button {
                onRecordVoice()
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
        .disabled(isQuickCaptureBusy)
    }

    private var createButton: some View {
        Button {
            onCreate()
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
        .tint(isCreateEnabled ? AppStyle.Colors.Status.todo : AppStyle.Colors.disabledControl)
        .buttonStyle(.glass)
        .disabled(!isCreateEnabled)
    }
}

#Preview("Add Task Action Bar Ready") {
    AddTaskActionBarPreview(
        quickCaptureMessage: nil,
        isCreateEnabled: true
    )
}

#Preview("Add Task Action Bar Manual Review") {
    AddTaskActionBarPreview(
        quickCaptureMessage: "Text captured. Apple Intelligence is unavailable, so the text was added for manual review.",
        quickCaptureMessageColor: AppStyle.Colors.warning,
        isCreateEnabled: true
    )
}

#Preview("Add Task Action Bar Importing") {
    AddTaskActionBarPreview(
        isImportingQuickCapturePhoto: true,
        isQuickCaptureBusy: true,
        isCreateEnabled: false
    )
}

#Preview("Add Task Action Bar Disabled") {
    AddTaskActionBarPreview(
        quickCaptureMessage: "Draft generated. Review and adjust before creating the task.",
        quickCaptureMessageColor: AppStyle.Colors.doneAccent,
        isCreateEnabled: false
    )
}

private struct AddTaskActionBarPreview: View {
    let isImportingQuickCapturePhoto: Bool
    let quickCaptureMessage: String?
    let quickCaptureMessageColor: Color
    let isQuickCaptureBusy: Bool
    let isCreateEnabled: Bool

    init(
        isImportingQuickCapturePhoto: Bool = false,
        quickCaptureMessage: String? = nil,
        quickCaptureMessageColor: Color = .secondary,
        isQuickCaptureBusy: Bool = false,
        isCreateEnabled: Bool = true
    ) {
        self.isImportingQuickCapturePhoto = isImportingQuickCapturePhoto
        self.quickCaptureMessage = quickCaptureMessage
        self.quickCaptureMessageColor = quickCaptureMessageColor
        self.isQuickCaptureBusy = isQuickCaptureBusy
        self.isCreateEnabled = isCreateEnabled
    }

    var body: some View {
        AddTaskActionBar(
            isImportingQuickCapturePhoto: isImportingQuickCapturePhoto,
            quickCaptureMessage: quickCaptureMessage,
            quickCaptureMessageColor: quickCaptureMessageColor,
            isQuickCaptureBusy: isQuickCaptureBusy,
            isCreateEnabled: isCreateEnabled,
            onPasteNote: {},
            onImportPhoto: {},
            onScanText: {},
            onRecordVoice: {},
            onCreate: {}
        )
        .padding(AppStyle.Spacing.extraLarge)
        .background(AppStyle.Colors.background)
        .previewLayout(.sizeThatFits)
    }
}
