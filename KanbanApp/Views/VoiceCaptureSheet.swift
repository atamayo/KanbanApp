import SwiftUI

struct VoiceCaptureSheet: View {
    let onRecognizedText: (String) -> Void
    let onError: (VoiceCaptureError) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceCapture = VoiceCaptureService()
    @State private var hasRequestedStart = false

    private var cleanedTranscript: String {
        voiceCapture.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canUseTranscript: Bool {
        !cleanedTranscript.isEmpty && !voiceCapture.isRecording
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.extraLarge) {
                header
                transcriptCard
                controls
                Spacer(minLength: AppStyle.Spacing.none)
            }
            .padding(AppStyle.Spacing.extraLarge)
            .background(AppStyle.Colors.background)
            .navigationTitle("Record Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        voiceCapture.cancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Use Transcript") {
                        guard canUseTranscript else { return }
                        dismiss()
                        onRecognizedText(cleanedTranscript)
                    }
                    .disabled(!canUseTranscript)
                }
            }
        }
        .task {
            guard !hasRequestedStart else { return }
            hasRequestedStart = true
            await voiceCapture.start()
        }
        .onChange(of: voiceCapture.error) { _, newValue in
            guard let newValue else { return }
            onError(newValue)
        }
        .onDisappear {
            voiceCapture.cancel()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                ZStack {
                    Circle()
                        .fill(recordingTint.opacity(AppStyle.Opacity.accentWashSelected))
                        .frame(width: AppStyle.Shapes.iconBadgeLarge, height: AppStyle.Shapes.iconBadgeLarge)

                    Image(systemName: voiceCapture.isRecording ? "waveform" : "mic.fill")
                        .font(AppStyle.Typography.iconHero)
                        .foregroundStyle(recordingTint)
                }

                VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                    Text(voiceCapture.isRecording ? "Listening..." : "Review your transcript")
                        .font(AppStyle.Typography.metricMedium)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Text("Describe one task naturally. You can edit the generated task before saving.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Transcript")
                .sectionHeaderStyle()

            ScrollView {
                Text(cleanedTranscript.isEmpty ? "Your dictated task will appear here." : cleanedTranscript)
                    .font(AppStyle.Typography.formField)
                    .foregroundStyle(cleanedTranscript.isEmpty ? AppStyle.Colors.secondaryText : AppStyle.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: AppStyle.Shapes.voiceTranscriptMinHeight)

            if let error = voiceCapture.error {
                Text(error.localizedDescription)
                    .font(AppStyle.Typography.guidanceFooter)
                    .foregroundStyle(AppStyle.Colors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppStyle.Spacing.large)
        .background(AppStyle.Colors.surface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
        )
    }

    private var controls: some View {
        HStack(spacing: AppStyle.Spacing.medium) {
            Button {
                voiceCapture.clear()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
                    .frame(height: AppStyle.Shapes.fabSize)
            }
            .buttonStyle(.glass)
            .disabled(cleanedTranscript.isEmpty || voiceCapture.isRecording)

            Button {
                if voiceCapture.isRecording {
                    voiceCapture.stop()
                } else {
                    Task { await voiceCapture.start() }
                }
            } label: {
                Label(voiceCapture.isRecording ? "Stop" : "Record Again", systemImage: voiceCapture.isRecording ? "stop.circle.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: AppStyle.Shapes.fabSize)
            }
            .buttonStyle(.glassProminent)
            .tint(recordingTint)
        }
    }

    private var recordingTint: Color {
        voiceCapture.error == nil ? AppStyle.Colors.Status.todo : AppStyle.Colors.warning
    }
}
