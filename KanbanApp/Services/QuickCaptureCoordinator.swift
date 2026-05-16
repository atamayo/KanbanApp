import Combine
import Foundation
import PhotosUI
import SwiftUI

enum QuickCaptureCoordinatorResult {
    case none
    case applyDraft(QuickCaptureTaskDraft, message: String)
    case applyManualText(String, source: QuickCaptureSource)
    case showReviewSheet
}

@MainActor
final class QuickCaptureCoordinator: ObservableObject {
    @Published var text = ""
    @Published var message: String?
    @Published var draftMessage: String?
    @Published var isGenerating = false
    @Published var isImportingPhoto = false
    @Published private(set) var isAvailable = false
    @Published private(set) var unavailableMessage: String?

    init() {
        refreshAvailability()
    }

    func preparePasteCapture() {
        refreshAvailability()
        draftMessage = isAvailable ? nil : QuickCaptureSource.paste.reviewMessage
    }

    func generateDraftFromCurrentText() async -> QuickCaptureCoordinatorResult {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return .none }

        refreshAvailability()
        guard isAvailable else {
            draftMessage = unavailableMessage
            return .none
        }

        isGenerating = true
        draftMessage = nil

        defer { isGenerating = false }

        do {
            let draft = try await QuickCaptureTaskGenerator.generate(from: cleanedText)
            text = cleanedText
            return .applyDraft(draft, message: QuickCaptureSource.paste.successMessage)
        } catch {
            draftMessage = "Quick Capture AI couldn’t generate a draft right now. Try shortening the note and retry."
            return .none
        }
    }

    func importPhoto(_ item: PhotosPickerItem) async -> QuickCaptureCoordinatorResult {
        isImportingPhoto = true
        message = nil
        draftMessage = nil

        defer { isImportingPhoto = false }

        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                message = "The selected image could not be loaded."
                return .none
            }

            let extractedText = try await ImageTextExtractionService.extractText(from: imageData)
            return await handleRecognizedText(extractedText, source: .photo)
        } catch let error as ImageTextExtractionError {
            message = error.localizedDescription
            return .none
        } catch {
            message = "The image text was extracted, but the AI draft couldn’t be generated right now. Review it and generate again."
            return .showReviewSheet
        }
    }

    func handleRecognizedText(_ recognizedText: String, source: QuickCaptureSource) async -> QuickCaptureCoordinatorResult {
        let cleanedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else {
            message = LiveTextScannerError.noTextFound.localizedDescription
            return .none
        }

        text = cleanedText
        draftMessage = source.reviewMessage

        refreshAvailability()
        guard isAvailable else {
            return .applyManualText(cleanedText, source: source)
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let draft = try await QuickCaptureTaskGenerator.generate(from: cleanedText)
            return .applyDraft(draft, message: source.successMessage)
        } catch {
            message = source.generationFailureMessage
            return .showReviewSheet
        }
    }

    func markDraftApplied(message: String) {
        self.message = message
    }

    func markManualTextApplied(_ cleanedText: String, source: QuickCaptureSource) {
        text = cleanedText
        draftMessage = nil
        message = source.manualAppliedMessage
    }

    func clearFeedback() {
        message = nil
        draftMessage = nil
    }

    func showMessage(_ message: String) {
        self.message = message
    }

    private func refreshAvailability() {
        switch QuickCaptureTaskGenerator.availability {
        case .available:
            isAvailable = true
            unavailableMessage = nil
        case .unavailable(let message):
            isAvailable = false
            unavailableMessage = message
        }
    }
}
