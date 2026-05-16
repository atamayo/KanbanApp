import AVFoundation
import Combine
import Speech

enum VoiceCaptureError: LocalizedError {
    case speechRecognitionDenied
    case microphoneDenied
    case recognizerUnavailable
    case audioSetupFailed
    case noSpeechFound

    var errorDescription: String? {
        switch self {
        case .speechRecognitionDenied:
            return String(localized: "Speech recognition access is required to dictate tasks. Enable it in Settings.")
        case .microphoneDenied:
            return String(localized: "Microphone access is required to dictate tasks. Enable it in Settings.")
        case .recognizerUnavailable:
            return String(localized: "Voice dictation is unavailable right now. Try again in a moment.")
        case .audioSetupFailed:
            return String(localized: "The microphone could not be started. Check audio permissions and try again.")
        case .noSpeechFound:
            return String(localized: "No speech was captured. Try recording again.")
        }
    }
}

@MainActor
final class VoiceCaptureService: NSObject, ObservableObject {
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
