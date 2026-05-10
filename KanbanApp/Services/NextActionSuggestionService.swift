import Foundation
import FoundationModels

@Generable
struct NextActionSuggestionDraft {
    @Guide(description: "One short, concrete, physical next step that can move the task forward now.")
    var nextAction: String
}

enum NextActionSuggestionService {
    private static let model = SystemLanguageModel.default

    static var availability: QuickCaptureAvailability {
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailable("Apple Intelligence is not supported on this device.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable("Turn on Apple Intelligence in Settings to suggest a next action.")
        case .unavailable(.modelNotReady):
            return .unavailable("Apple Intelligence is getting ready. Try again in a moment.")
        case .unavailable:
            return .unavailable("Next Action suggestion is unavailable right now.")
        }
    }

    static func generate(for task: TaskItem) async throws -> String {
        let session = LanguageModelSession(
            instructions: """
            You help a personal kanban app reduce friction by suggesting exactly one next action.

            Rules:
            - Return one sentence only.
            - Start with a strong verb.
            - Make it concrete and observable.
            - Keep it small enough to start now.
            - Do not produce a checklist.
            - Do not restate the task title unless necessary.
            - If the task is blocked, suggest the smallest unblock step.
            """
        )

        let response = try await session.respond(
            to: """
            Suggest the single best next action for this task.

            Title: \(task.title)
            Description: \(task.desc)
            Definition of Done: \(task.completionCriteria)
            Status: \(task.status.rawValue)
            Priority: \(task.priority.rawValue)
            Blocked: \(task.isBlocked ? "Yes" : "No")
            """,
            generating: NextActionSuggestionDraft.self
        )

        return response.content.nextAction.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
