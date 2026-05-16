import SwiftUI

struct QuickCaptureDraftSheet: View {
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
