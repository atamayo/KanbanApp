import AVFoundation
import Speech
import SwiftUI

enum VoiceCaptureError: LocalizedError {
    case speechRecognitionDenied
    case microphoneDenied
    case recognizerUnavailable
    case audioSetupFailed
    case noSpeechFound

    var errorDescription: String? {
        switch self {
        case .speechRecognitionDenied:
            return "Speech recognition access is required to dictate tasks. Enable it in Settings."
        case .microphoneDenied:
            return "Microphone access is required to dictate tasks. Enable it in Settings."
        case .recognizerUnavailable:
            return "Voice dictation is unavailable right now. Try again in a moment."
        case .audioSetupFailed:
            return "The microphone could not be started. Check audio permissions and try again."
        case .noSpeechFound:
            return "No speech was captured. Try recording again."
        }
    }
}

struct VoiceCaptureSheet: View {
    let onRecognizedText: (String) -> Void
    let onError: (VoiceCaptureError) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceCaptureRecorder()
    @State private var hasRequestedStart = false

    private var cleanedTranscript: String {
        recorder.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canUseTranscript: Bool {
        !cleanedTranscript.isEmpty && !recorder.isRecording
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
                        recorder.cancel()
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
            await recorder.start()
        }
        .onChange(of: recorder.error) { _, newValue in
            guard let newValue else { return }
            onError(newValue)
        }
        .onDisappear {
            recorder.cancel()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                ZStack {
                    Circle()
                        .fill(recordingTint.opacity(AppStyle.Opacity.accentWashSelected))
                        .frame(width: AppStyle.Shapes.iconBadgeLarge, height: AppStyle.Shapes.iconBadgeLarge)

                    Image(systemName: recorder.isRecording ? "waveform" : "mic.fill")
                        .font(AppStyle.Typography.iconHero)
                        .foregroundStyle(recordingTint)
                }

                VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                    Text(recorder.isRecording ? "Listening..." : "Review your transcript")
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

            if let error = recorder.error {
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
                recorder.clear()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
                    .frame(height: AppStyle.Shapes.fabSize)
            }
            .buttonStyle(.glass)
            .disabled(cleanedTranscript.isEmpty || recorder.isRecording)

            Button {
                if recorder.isRecording {
                    recorder.stop()
                } else {
                    Task { await recorder.start() }
                }
            } label: {
                Label(recorder.isRecording ? "Stop" : "Record Again", systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: AppStyle.Shapes.fabSize)
            }
            .buttonStyle(.glassProminent)
            .tint(recordingTint)
        }
    }

    private var recordingTint: Color {
        recorder.error == nil ? AppStyle.Colors.Status.todo : AppStyle.Colors.warning
    }
}

@MainActor
private final class VoiceCaptureRecorder: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var error: VoiceCaptureError?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func start() async {
        guard !isRecording else { return }

        error = nil
        let speechAuthorized = await requestSpeechAuthorization()
        guard speechAuthorized else {
            error = .speechRecognitionDenied
            return
        }

        let microphoneAuthorized = await requestMicrophoneAuthorization()
        guard microphoneAuthorized else {
            error = .microphoneDenied
            return
        }

        guard speechRecognizer?.isAvailable == true else {
            error = .recognizerUnavailable
            return
        }

        do {
            try beginRecording()
        } catch {
            self.error = .audioSetupFailed
            stop()
        }
    }

    func stop() {
        guard isRecording || audioEngine.isRunning else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func cancel() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func clear() {
        transcript = ""
        error = nil
    }

    private func beginRecording() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, taskError in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.stop()
                    }
                }

                if taskError != nil {
                    self.stop()
                    if self.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.error = .noSpeechFound
                    }
                }
            }
        }
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
