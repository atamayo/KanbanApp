import XCTest
@testable import KanbanApp

@MainActor
final class TaskChatPromptTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_750_000_000)
    private let expectedVisualizationKindsByPromptID: [String: [TaskChatVisualizationKind]] = [
        "closed-this-month": [],
        "longest-to-close": [],
        "active-attention": [],
        "status-chart": [.statusBreakdown],
        "blocked-table": [.blockedTasks],
        "active-aging-chart": [.activeAging],
        "priority-chart": [.priorityBreakdown],
        "slowest-ranking": [.slowestClosed],
        "closed-this-month-list": [.completedThisMonth],
        "blocked-count": [],
        "weekly-throughput-chart": [.throughputTrend],
        "week-comparison": [.weekComparison],
        "close-time-trend": [],
        "priority-close-time": [.priorityCloseTime],
        "closing-more-than-last-week": [],
        "month-comparison": [.monthComparison],
        "cycle-time-worse": [],
        "cycle-time-chart": [.closeTimeTrend],
        "best-week": [],
        "high-priority-close-time": [],
        "weekly-throughput-table": [.throughputTrend],
        "completed-this-month-chart": [.completedThisMonth],
        "active-age-table": [.activeAging],
        "oldest-active-task": [],
        "oldest-blocked-task": [],
        "average-close-time": [],
        "close-time-table": [.closeTimeTrend],
        "priority-close-time-chart": [.priorityCloseTime],
        "month-comparison-chart": [.monthComparison],
        "blocked-age-chart": [.blockedTasks],
        "closed-last-seven-days": [],
        "fastest-priority": []
    ]

    func testAvailablePromptCatalogHasUniqueNonEmptyPrompts() {
        let prompts = TaskChatStarterPrompt.availablePrompts

        XCTAssertEqual(prompts.count, expectedVisualizationKindsByPromptID.count)
        XCTAssertEqual(Set(prompts.map(\.id)), Set(expectedVisualizationKindsByPromptID.keys))
        XCTAssertEqual(Set(prompts.map(\.id)).count, prompts.count)
        XCTAssertFalse(prompts.contains { $0.id.isEmpty })
        XCTAssertFalse(prompts.contains { $0.requestText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }

    func testEveryAvailablePromptHasExpectedVisualizationRouting() {
        for prompt in TaskChatStarterPrompt.availablePrompts {
            let expectedKinds = expectedVisualizationKindsByPromptID[prompt.id]
            XCTAssertNotNil(expectedKinds, "Missing test coverage for prompt \(prompt.id)")
            XCTAssertEqual(
                TaskChatService.inferredVisualizationKinds(for: prompt.requestText),
                expectedKinds,
                "Unexpected visualization routing for \(prompt.id)"
            )
        }
    }

    func testEveryAvailablePromptCanBuildAnswerSourcesOrVisualizations() {
        let snapshot = TaskChatBoardSnapshot(tasks: promptFixtureTasks(), now: now)

        for prompt in TaskChatStarterPrompt.availablePrompts {
            let expectedKinds = expectedVisualizationKindsByPromptID[prompt.id] ?? []
            let visualizations = snapshot.visualizations(for: expectedKinds)
            XCTAssertEqual(visualizations.map(\.kind), expectedKinds, "Missing visualization for \(prompt.id)")

            if expectedKinds.isEmpty {
                XCTAssertNotNil(
                    snapshot.evidence(for: prompt.requestText, metricSummary: "Prompt metric"),
                    "Missing answer source evidence for \(prompt.id)"
                )
            } else {
                XCTAssertFalse(visualizations.isEmpty, "Expected visualization for \(prompt.id)")
                if prompt.requestText.localizedCaseInsensitiveContains("table") ||
                    prompt.requestText.localizedCaseInsensitiveContains("list") ||
                    prompt.requestText.localizedCaseInsensitiveContains("ranking") {
                    XCTAssertTrue(visualizations.contains { $0.table != nil }, "Expected table-capable visualization for \(prompt.id)")
                }
                if prompt.requestText.localizedCaseInsensitiveContains("chart") {
                    XCTAssertTrue(visualizations.contains { !$0.bars.isEmpty }, "Expected chart-capable visualization for \(prompt.id)")
                }
            }
        }
    }

    func testEveryContextualWIPActionHasPromptCoverage() {
        let cases: [(action: WIPCoachActionType, expectedPromptIDs: [String])] = [
            (.pullNextTask, ["wip-why-this-task", "wip-can-pull", "wip-active-risks"]),
            (.focusCurrentTask, ["wip-finish-first", "wip-why-focus", "wip-active-risks"]),
            (.unblockTask, ["wip-blocking-flow", "wip-finish-first", "wip-active-risks"]),
            (.reduceWIP, ["wip-reduce", "wip-finish-first", "wip-active-risks"]),
            (.breakDownTask, ["wip-break-down", "wip-finish-first", "wip-active-risks"]),
            (.noActionNeeded, ["wip-next", "wip-can-pull", "wip-active-risks"])
        ]

        for testCase in cases {
            let prompts = TaskChatStarterPrompt.contextualPrompts(for: makeManualContext(action: testCase.action))
            XCTAssertEqual(prompts.map(\.id), testCase.expectedPromptIDs)
            XCTAssertFalse(prompts.contains { $0.requestText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        }
    }

    func testPullNextTaskContextOffersCanPullPrompt() throws {
        let readyTask = makeTask("Prepare bike for summer")
        let context = makeContext(tasks: [readyTask], maxActiveTasks: 3)

        XCTAssertEqual(context.action, .pullNextTask)
        XCTAssertEqual(context.activeCount, 0)
        XCTAssertEqual(context.slotsLeft, 3)

        let prompts = TaskChatStarterPrompt.contextualPrompts(for: context)
        XCTAssertEqual(prompts.map(\.id), [
            "wip-why-this-task",
            "wip-can-pull",
            "wip-active-risks"
        ])

        let canPullPrompt = try XCTUnwrap(prompts.first { $0.id == "wip-can-pull" })
        XCTAssertEqual(canPullPrompt.requestText, "Can I safely pull more work right now?")
    }

    func testAtLimitContextDoesNotOfferCanPullPrompt() {
        let activeTask = makeTask("Finish expense report", status: .inProgress)
        let context = makeContext(tasks: [activeTask], maxActiveTasks: 1)

        XCTAssertEqual(context.action, .focusCurrentTask)
        XCTAssertEqual(context.activeCount, 1)
        XCTAssertEqual(context.slotsLeft, 0)

        let promptIDs = TaskChatStarterPrompt.contextualPrompts(for: context).map(\.id)
        XCTAssertEqual(promptIDs, [
            "wip-finish-first",
            "wip-why-focus",
            "wip-active-risks"
        ])
        XCTAssertFalse(promptIDs.contains("wip-can-pull"))
    }

    func testCanPullPromptUsesCoachContextWhenSlotIsAvailable() async throws {
        let readyTask = makeTask("Prepare bike for summer")
        let context = makeContext(tasks: [readyTask], maxActiveTasks: 3)
        let prompt = try XCTUnwrap(
            TaskChatStarterPrompt.contextualPrompts(for: context).first { $0.id == "wip-can-pull" }
        )

        let response = try await TaskChatService.respond(
            to: TaskChatRequest(
                question: prompt.requestText,
                previousTurns: [],
                tasks: [readyTask],
                context: context,
                now: now,
                locale: Locale(identifier: "en_US")
            )
        )

        XCTAssertTrue(response.answer.contains(readyTask.title))
        XCTAssertFalse(response.answer.localizedCaseInsensitiveContains("not recommended"))
        XCTAssertEqual(response.metricSummary, context.headline)
        XCTAssertEqual(response.referencedTaskIDs, [readyTask.id])
        XCTAssertTrue(response.proposedActions.isEmpty)
        XCTAssertTrue(response.visualizations.isEmpty)
        XCTAssertEqual(response.evidence?.rows.first?.value, context.headline)
    }

    func testCanPullPromptUsesCoachContextWhenWIPLimitIsReached() async throws {
        let activeTask = makeTask("Finish expense report", status: .inProgress)
        let context = makeContext(tasks: [activeTask], maxActiveTasks: 1)

        let response = try await TaskChatService.respond(
            to: TaskChatRequest(
                question: "Can I safely pull more work right now?",
                previousTurns: [],
                tasks: [activeTask],
                context: context,
                now: now,
                locale: Locale(identifier: "en_US")
            )
        )

        XCTAssertEqual(response.answer, context.reason)
        XCTAssertEqual(response.metricSummary, context.headline)
        XCTAssertEqual(response.referencedTaskIDs, [activeTask.id])
        XCTAssertFalse(response.answer.localizedCaseInsensitiveContains("safely pull one more task"))
        XCTAssertTrue(response.proposedActions.isEmpty)
        XCTAssertTrue(response.visualizations.isEmpty)
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

    private func makeManualContext(action: WIPCoachActionType) -> TaskChatContext {
        let recommendedTask = action == .noActionNeeded ? nil : makeTask("Context prompt fixture")
        let candidate = recommendedTask.map {
            WIPCoachTaskCandidate(task: $0, score: 50, reason: "Prompt fixture")
        }

        return TaskChatContext(
            recommendation: WIPCoachRecommendation(
                pressure: pressure(for: action),
                action: action,
                headline: "Prompt fixture headline",
                body: "Prompt fixture body",
                ctaTitle: "Prompt fixture CTA",
                label: "Prompt fixture label",
                recommendedTask: recommendedTask,
                reason: "Prompt fixture reason",
                stats: WIPCoachStats(
                    activeCount: action == .pullNextTask || action == .noActionNeeded ? 0 : 1,
                    wipLimit: 3,
                    slotsLeft: action == .pullNextTask || action == .noActionNeeded ? 3 : 0,
                    blockedCount: action == .unblockTask ? 1 : 0,
                    readyCount: action == .noActionNeeded ? 0 : 1
                ),
                readyAlternatives: candidate.map { [$0] } ?? [],
                activeTasks: recommendedTask.map { [$0] } ?? []
            )
        )
    }

    private func pressure(for action: WIPCoachActionType) -> WIPPressureLevel {
        switch action {
        case .pullNextTask:
            return .hasRoom
        case .focusCurrentTask:
            return .atLimit
        case .unblockTask:
            return .blocked
        case .reduceWIP:
            return .overloaded
        case .breakDownTask:
            return .nearLimit
        case .noActionNeeded:
            return .healthy
        }
    }

    private func promptFixtureTasks() -> [TaskItem] {
        let todo = makeTask("Prepare bike for summer", status: .todo, priority: .medium, order: 0)
        todo.createdAt = now.addingTimeInterval(-10 * 86_400)
        todo.lastStatusChange = now.addingTimeInterval(-9 * 86_400)

        let active = makeTask("Finish expense report", status: .inProgress, priority: .high, order: 1)
        active.enteredInProgressAt = now.addingTimeInterval(-4 * 86_400)
        active.lastStatusChange = active.enteredInProgressAt ?? active.lastStatusChange

        let blocked = makeTask("Resolve vendor blocker", status: .inProgress, priority: .medium, isBlocked: true, order: 2)
        blocked.enteredInProgressAt = now.addingTimeInterval(-6 * 86_400)
        blocked.lastStatusChange = blocked.enteredInProgressAt ?? blocked.lastStatusChange

        let doneThisWeek = makeTask("Ship weekly report", status: .done, priority: .high, order: 3)
        doneThisWeek.createdAt = now.addingTimeInterval(-8 * 86_400)
        doneThisWeek.finalizedAt = now.addingTimeInterval(-2 * 86_400)
        doneThisWeek.updatedAt = doneThisWeek.finalizedAt ?? doneThisWeek.updatedAt

        let doneLastWeek = makeTask("Close invoice review", status: .done, priority: .medium, order: 4)
        doneLastWeek.createdAt = now.addingTimeInterval(-18 * 86_400)
        doneLastWeek.finalizedAt = now.addingTimeInterval(-10 * 86_400)
        doneLastWeek.updatedAt = doneLastWeek.finalizedAt ?? doneLastWeek.updatedAt

        let doneLastMonth = makeTask("Finish tax checklist", status: .done, priority: .low, order: 5)
        doneLastMonth.createdAt = now.addingTimeInterval(-50 * 86_400)
        doneLastMonth.finalizedAt = now.addingTimeInterval(-40 * 86_400)
        doneLastMonth.updatedAt = doneLastMonth.finalizedAt ?? doneLastMonth.updatedAt

        return [todo, active, blocked, doneThisWeek, doneLastWeek, doneLastMonth]
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
            description: "Enough context to make this task ready for prompt testing.",
            completionCriteria: "The prompt behavior has been verified.",
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
