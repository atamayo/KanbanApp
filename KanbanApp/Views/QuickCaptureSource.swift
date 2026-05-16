enum QuickCaptureSource {
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
