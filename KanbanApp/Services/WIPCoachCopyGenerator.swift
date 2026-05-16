import Foundation
import FoundationModels

@Generable
struct WIPCoachCopyDraft {
    @Guide(description: "A short, calm coaching headline. Keep it under 8 words.")
    var headline: String

    @Guide(description: "One or two concise sentences explaining the recommended WIP move. Do not invent facts.")
    var body: String

    @Guide(description: "A short reason for the recommended task or action. Keep it under 8 words.")
    var recommendationReason: String
}

struct WIPCoachCopyRequest: Equatable {
    let signature: String
    let pressure: String
    let action: String
    let activeCount: Int
    let wipLimit: Int
    let slotsLeft: Int
    let blockedCount: Int
    let readyCount: Int
    let fallbackHeadline: String
    let fallbackBody: String
    let fallbackReason: String
    let recommendedTask: String
    let recommendedTaskStatus: String
    let recommendedTaskPriority: String
    let recommendedTaskBlocked: Bool
    let readyAlternatives: [String]
    let activeTasks: [String]

    init(recommendation: WIPCoachRecommendation) {
        let recommendedTask = recommendation.recommendedTask
        let readyAlternatives = recommendation.readyAlternatives.map {
            "\($0.task.title) | priority: \($0.task.priority.rawValue) | reason: \($0.reason)"
        }
        let activeTasks = recommendation.activeTasks.map {
            "\($0.title) | priority: \($0.priority.rawValue) | blocked: \($0.isBlocked ? "yes" : "no")"
        }

        pressure = recommendation.pressure.copyName
        action = recommendation.action.copyName
        activeCount = recommendation.stats.activeCount
        wipLimit = recommendation.stats.wipLimit
        slotsLeft = recommendation.stats.slotsLeft
        blockedCount = recommendation.stats.blockedCount
        readyCount = recommendation.stats.readyCount
        fallbackHeadline = recommendation.headline
        fallbackBody = recommendation.body
        fallbackReason = recommendation.reason
        self.recommendedTask = recommendedTask?.title ?? "None"
        recommendedTaskStatus = recommendedTask?.status.rawValue ?? "None"
        recommendedTaskPriority = recommendedTask?.priority.rawValue ?? "None"
        recommendedTaskBlocked = recommendedTask?.isBlocked ?? false
        self.readyAlternatives = readyAlternatives
        self.activeTasks = activeTasks

        signature = [
            pressure,
            action,
            "\(activeCount)",
            "\(wipLimit)",
            "\(slotsLeft)",
            "\(blockedCount)",
            "\(readyCount)",
            recommendedTask?.id.uuidString ?? "none",
            recommendedTask?.updatedAt.timeIntervalSince1970.description ?? "0",
            readyAlternatives.joined(separator: ";"),
            activeTasks.joined(separator: ";")
        ].joined(separator: "|")
    }

    var prompt: String {
        """
        Generate natural WIP coaching copy for a Personal Kanban app.

        Deterministic recommendation:
        Pressure: \(pressure)
        Action: \(action)
        Active: \(activeCount)/\(wipLimit)
        Slots left: \(slotsLeft)
        Blocked tasks: \(blockedCount)
        Ready tasks: \(readyCount)
        Recommended task: \(recommendedTask)
        Recommended task status: \(recommendedTaskStatus)
        Recommended task priority: \(recommendedTaskPriority)
        Recommended task blocked: \(recommendedTaskBlocked ? "yes" : "no")
        Existing reason: \(fallbackReason)

        Ready alternatives:
        \(readyAlternatives.isEmpty ? "None" : readyAlternatives.joined(separator: "\n"))

        Active tasks:
        \(activeTasks.isEmpty ? "None" : activeTasks.joined(separator: "\n"))

        Fallback copy:
        Headline: \(fallbackHeadline)
        Body: \(fallbackBody)
        Reason: \(fallbackReason)
        """
    }
}

enum WIPCoachCopyGenerator {
    private static let model = SystemLanguageModel.default

    static var availability: QuickCaptureAvailability {
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailable(String(localized: "Apple Intelligence is not supported on this device."))
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable(String(localized: "Turn on Apple Intelligence in Settings to personalize WIP coaching."))
        case .unavailable(.modelNotReady):
            return .unavailable(String(localized: "Apple Intelligence is getting ready. Try again in a moment."))
        case .unavailable:
            return .unavailable(String(localized: "WIP Coach AI copy is unavailable right now."))
        }
    }

    static func generate(for request: WIPCoachCopyRequest) async throws -> WIPCoachCopyDraft {
        let session = LanguageModelSession(
            instructions: """
            You write concise coaching copy for a Personal Kanban WIP Pressure Coach.

            Rules:
            - Improve the wording only. Do not change the deterministic recommendation.
            - Keep the tone calm, direct, helpful, and native app-like.
            - Do not invent due dates, dependencies, estimates, task ages, people, or project facts.
            - Do not recommend pulling new work when the action is focus current task, unblock task, or reduce WIP.
            - Do not mention Apple Intelligence or AI.
            - Use the recommended task title only when it helps clarity.
            - Keep the headline short.
            - Keep the body to one or two sentences.
            - Keep the recommendation reason short.
            """
        )

        let response = try await session.respond(
            to: request.prompt,
            generating: WIPCoachCopyDraft.self
        )

        return response.content
    }
}

extension WIPCoachCopyDraft {
    var hasUsableContent: Bool {
        headline.trimmedNonEmpty != nil ||
        body.trimmedNonEmpty != nil ||
        recommendationReason.trimmedNonEmpty != nil
    }
}

extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension WIPPressureLevel {
    var copyName: String {
        switch self {
        case .hasRoom:
            return "Has room"
        case .healthy:
            return "Healthy"
        case .nearLimit:
            return "Near limit"
        case .atLimit:
            return "At limit"
        case .overloaded:
            return "Overloaded"
        case .blocked:
            return "Blocked"
        }
    }
}

private extension WIPCoachActionType {
    var copyName: String {
        switch self {
        case .pullNextTask:
            return "Pull next task"
        case .focusCurrentTask:
            return "Focus current task"
        case .unblockTask:
            return "Unblock task"
        case .reduceWIP:
            return "Reduce WIP"
        case .breakDownTask:
            return "Break down task"
        case .noActionNeeded:
            return "No action needed"
        }
    }
}
