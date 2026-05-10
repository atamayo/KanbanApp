import Foundation
import FoundationModels

@Generable
struct QuickCaptureTaskDraft {
    @Guide(description: "A clear, action-oriented task title with 3 to 8 words.")
    var title: String

    @Guide(description: "A concise description with only the most useful context. Leave empty if the title is enough.")
    var taskDescription: String

    @Guide(description: "A short definition of done that makes completion explicit. Leave empty if unknown.")
    var definitionOfDone: String

    @Guide(description: "A single concrete next action in imperative form, like 'email design draft to Anna'. Leave empty if unnecessary.")
    var nextAction: String

    @Guide(description: "One of: High, Medium, or Low.")
    var priority: String
}

enum QuickCaptureAvailability: Equatable {
    case available
    case unavailable(String)
}

enum QuickCaptureTaskGenerator {
    private static let model = SystemLanguageModel.default

    static var availability: QuickCaptureAvailability {
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailable("Apple Intelligence is not supported on this device.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable("Turn on Apple Intelligence in Settings to use Quick Capture AI.")
        case .unavailable(.modelNotReady):
            return .unavailable("Apple Intelligence is getting ready. Try again in a moment.")
        case .unavailable:
            return .unavailable("Quick Capture AI is unavailable right now.")
        }
    }

    static func generate(from rawText: String) async throws -> QuickCaptureTaskDraft {
        let session = LanguageModelSession(
            instructions: """
            You turn messy personal notes into focused Personal Kanban tasks.

            Rules:
            - Prefer one concrete task, not a project plan.
            - Make the title specific and action-oriented.
            - Keep the description short and useful.
            - Make the definition of done explicit when possible.
            - Suggest exactly one next action when it helps reduce ambiguity.
            - Choose High only when the note sounds urgent, risky, or strongly time-sensitive.
            - Default to Medium when priority is unclear.
            - Return only information grounded in the note.
            """
        )

        let response = try await session.respond(
            to: """
            Convert this note into a task draft for a personal kanban app:

            \(rawText)
            """,
            generating: QuickCaptureTaskDraft.self
        )

        return response.content
    }

    static func taskPriority(from rawPriority: String) -> TaskPriority {
        switch rawPriority.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "high":
            return .high
        case "low":
            return .low
        default:
            return .medium
        }
    }
}
