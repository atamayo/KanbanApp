import XCTest
@testable import KanbanApp

@MainActor
final class TaskChatServiceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    func testGreetingReturnsSimpleResponseWithoutBoardArtifacts() async throws {
        let response = try await TaskChatService.respond(
            to: TaskChatRequest(
                question: "Hello there!",
                previousTurns: [],
                tasks: [],
                now: now,
                locale: Locale(identifier: "en_US")
            )
        )

        XCTAssertEqual(response.answer, String(localized: "Hi."))
        assertSimpleResponse(response)
    }

    func testThanksReturnsSimpleResponseWithoutBoardArtifacts() async throws {
        let response = try await TaskChatService.respond(
            to: TaskChatRequest(
                question: "Thank you very much",
                previousTurns: [],
                tasks: [],
                now: now,
                locale: Locale(identifier: "en_US")
            )
        )

        XCTAssertEqual(response.answer, String(localized: "You're welcome."))
        assertSimpleResponse(response)
    }

    func testPullCapacityQuestionAllowsStartingNextTaskWhenCoachRecommendsPulling() async throws {
        let task = makeTask("Prepare bike for summer")
        let context = makeContext(tasks: [task], maxActiveTasks: 3)

        let response = try await TaskChatService.respond(
            to: TaskChatRequest(
                question: "Should I start the next task now?",
                previousTurns: [],
                tasks: [task],
                context: context,
                now: now,
                locale: Locale(identifier: "en_US")
            )
        )

        XCTAssertEqual(context.action, .pullNextTask)
        XCTAssertTrue(response.answer.contains(String(localized: "You can safely pull one more task, but keep active work tight so current tasks can reach done.")))
        XCTAssertTrue(response.answer.contains(task.title))
        XCTAssertEqual(response.metricSummary, context.headline)
        XCTAssertEqual(response.referencedTaskIDs, [task.id])
        XCTAssertEqual(response.evidence?.rows.first?.value, context.headline)
        XCTAssertTrue(response.proposedActions.isEmpty)
        XCTAssertTrue(response.visualizations.isEmpty)
    }

    func testPullCapacityQuestionPrioritizesBlockedWorkBeforePulling() async throws {
        let blockedTask = makeTask("Resolve vendor blocker", status: .inProgress, isBlocked: true)
        let context = makeContext(tasks: [blockedTask], maxActiveTasks: 3)

        let response = try await TaskChatService.respond(
            to: TaskChatRequest(
                question: "Can I bring another task in now?",
                previousTurns: [],
                tasks: [blockedTask],
                context: context,
                now: now,
                locale: Locale(identifier: "en_US")
            )
        )

        XCTAssertEqual(context.action, .unblockTask)
        XCTAssertEqual(response.answer, String(localized: "Blocked tasks need attention before more work is pulled."))
        XCTAssertEqual(response.metricSummary, context.headline)
        XCTAssertEqual(response.referencedTaskIDs, [blockedTask.id])
        XCTAssertTrue(response.proposedActions.isEmpty)
        XCTAssertTrue(response.visualizations.isEmpty)
    }

    func testPullCapacityQuestionReturnsNoReadyWorkReasonWhenNoActionNeeded() async throws {
        let context = makeContext(tasks: [], maxActiveTasks: 3)

        let response = try await TaskChatService.respond(
            to: TaskChatRequest(
                question: "Can I pull more work right now?",
                previousTurns: [],
                tasks: [],
                context: context,
                now: now,
                locale: Locale(identifier: "en_US")
            )
        )

        XCTAssertEqual(context.action, .noActionNeeded)
        XCTAssertEqual(response.answer, context.reason)
        XCTAssertEqual(response.metricSummary, context.headline)
        XCTAssertTrue(response.referencedTaskIDs.isEmpty)
        XCTAssertTrue(response.proposedActions.isEmpty)
        XCTAssertTrue(response.visualizations.isEmpty)
    }

    func testTaskChatRequestPromptIncludesBoardFactsRecentTurnsAndContext() {
        let task = makeTask("Prepare bike for summer")
        let context = makeContext(tasks: [task], maxActiveTasks: 3)
        let request = TaskChatRequest(
            question: "Can I safely pull more work right now?",
            previousTurns: [
                TaskChatTurn(role: "assistant", content: "Previous answer"),
                TaskChatTurn(role: "user", content: "Previous question")
            ],
            tasks: [task],
            context: context,
            now: now,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertTrue(request.prompt.contains("User question:"))
        XCTAssertTrue(request.prompt.contains("Can I safely pull more work right now?"))
        XCTAssertTrue(request.prompt.contains("assistant: Previous answer"))
        XCTAssertTrue(request.prompt.contains("user: Previous question"))
        XCTAssertTrue(request.prompt.contains("Deterministic metrics:"))
        XCTAssertTrue(request.prompt.contains("- To Do: 1"))
        XCTAssertTrue(request.prompt.contains("Current WIP Coach context:"))
        XCTAssertTrue(request.prompt.contains("- Recommended action: Pull next task"))
        XCTAssertTrue(request.prompt.contains("- Slots left: 3"))
        XCTAssertTrue(request.prompt.contains(task.title))
    }

    private func assertSimpleResponse(_ response: TaskChatResponse) {
        XCTAssertTrue(response.metricSummary.isEmpty)
        XCTAssertTrue(response.referencedTaskIDs.isEmpty)
        XCTAssertTrue(response.proposedActions.isEmpty)
        XCTAssertTrue(response.visualizations.isEmpty)
        XCTAssertNil(response.evidence)
    }

    private func makeContext(
        tasks: [TaskItem],
        maxActiveTasks: Int,
        isFocusGuardEnabled: Bool = true
    ) -> TaskChatContext {
        TaskChatContext(
            recommendation: WIPCoachEngine.evaluate(
                tasks: tasks,
                maxActiveTasks: maxActiveTasks,
                isFocusGuardEnabled: isFocusGuardEnabled,
                now: now
            )
        )
    }

    private func makeTask(
        _ title: String,
        status: TaskStatus = .todo,
        priority: TaskPriority = .medium,
        isBlocked: Bool = false,
        order: Int = 0
    ) -> TaskItem {
        let task = TaskItem(
            title: title,
            description: "Enough context to make this task ready for service testing.",
            completionCriteria: "The service behavior has been verified.",
            status: status,
            priority: priority,
            isBlocked: isBlocked,
            order: order
        )
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000 + Double(order))
        task.createdAt = timestamp
        task.updatedAt = timestamp
        task.lastStatusChange = timestamp
        task.enteredInProgressAt = status == .inProgress ? timestamp : nil
        return task
    }
}
