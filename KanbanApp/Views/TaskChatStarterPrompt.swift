import Foundation

struct TaskChatStarterPrompt: Identifiable {
    let id: String
    let title: String
    let requestText: String

    static var availablePrompts: [TaskChatStarterPrompt] {
        [
            TaskChatStarterPrompt(
                id: "closed-this-month",
                title: String(localized: "How many tasks did I close this month?"),
                requestText: "How many tasks did I close this month?"
            ),
            TaskChatStarterPrompt(
                id: "longest-to-close",
                title: String(localized: "What task took longest to close?"),
                requestText: "What task took longest to close?"
            ),
            TaskChatStarterPrompt(
                id: "active-attention",
                title: String(localized: "Which active task needs attention?"),
                requestText: "Which active task needs attention?"
            ),
            TaskChatStarterPrompt(
                id: "status-chart",
                title: String(localized: "Show me a chart of my board status"),
                requestText: "Show me a chart of my board status"
            ),
            TaskChatStarterPrompt(
                id: "blocked-table",
                title: String(localized: "Show me a table of my blocked tasks"),
                requestText: "Show me a table of my blocked tasks"
            ),
            TaskChatStarterPrompt(
                id: "active-aging-chart",
                title: String(localized: "Show me a chart of active task aging"),
                requestText: "Show me a chart of active task aging"
            ),
            TaskChatStarterPrompt(
                id: "priority-chart",
                title: String(localized: "Show me a chart of task priorities"),
                requestText: "Show me a chart of task priorities"
            ),
            TaskChatStarterPrompt(
                id: "slowest-ranking",
                title: String(localized: "Show me a ranking of the slowest tasks to close"),
                requestText: "Show me a ranking of the slowest tasks to close"
            ),
            TaskChatStarterPrompt(
                id: "closed-this-month-list",
                title: String(localized: "List the tasks I closed this month"),
                requestText: "List the tasks I closed this month"
            ),
            TaskChatStarterPrompt(
                id: "blocked-count",
                title: String(localized: "How many active tasks are blocked?"),
                requestText: "How many active tasks are blocked?"
            ),
            TaskChatStarterPrompt(
                id: "weekly-throughput-chart",
                title: String(localized: "Show me my weekly throughput chart"),
                requestText: "Show me my weekly throughput chart"
            ),
            TaskChatStarterPrompt(
                id: "week-comparison",
                title: String(localized: "Compare this week with last week"),
                requestText: "Compare this week with last week"
            ),
            TaskChatStarterPrompt(
                id: "close-time-trend",
                title: String(localized: "Is my close time getting better?"),
                requestText: "Is my close time getting better?"
            ),
            TaskChatStarterPrompt(
                id: "priority-close-time",
                title: String(localized: "Show me average close time by priority"),
                requestText: "Show me average close time by priority"
            ),
            TaskChatStarterPrompt(
                id: "closing-more-than-last-week",
                title: String(localized: "Am I closing more tasks than last week?"),
                requestText: "Am I closing more tasks than last week?"
            ),
            TaskChatStarterPrompt(
                id: "month-comparison",
                title: String(localized: "Compare this month with last month"),
                requestText: "Compare this month with last month"
            ),
            TaskChatStarterPrompt(
                id: "cycle-time-worse",
                title: String(localized: "Is my cycle time getting worse?"),
                requestText: "Is my cycle time getting worse?"
            ),
            TaskChatStarterPrompt(
                id: "cycle-time-chart",
                title: String(localized: "Show me a chart of my close time trend"),
                requestText: "Show me a chart of my close time trend"
            ),
            TaskChatStarterPrompt(
                id: "best-week",
                title: String(localized: "Which week was my best?"),
                requestText: "Which week was my best?"
            ),
            TaskChatStarterPrompt(
                id: "high-priority-close-time",
                title: String(localized: "How long do high-priority tasks usually take to close?"),
                requestText: "How long do high-priority tasks usually take to close?"
            ),
            TaskChatStarterPrompt(
                id: "weekly-throughput-table",
                title: String(localized: "Show me a table of weekly throughput"),
                requestText: "Show me a table of weekly throughput"
            ),
            TaskChatStarterPrompt(
                id: "completed-this-month-chart",
                title: String(localized: "Show me a chart of tasks closed this month"),
                requestText: "Show me a chart of tasks closed this month"
            ),
            TaskChatStarterPrompt(
                id: "active-age-table",
                title: String(localized: "Show me a table of active tasks by age"),
                requestText: "Show me a table of active tasks by age"
            ),
            TaskChatStarterPrompt(
                id: "oldest-active-task",
                title: String(localized: "Which active task has been in progress the longest?"),
                requestText: "Which active task has been in progress the longest?"
            ),
            TaskChatStarterPrompt(
                id: "oldest-blocked-task",
                title: String(localized: "Which blocked task has been blocked the longest?"),
                requestText: "Which blocked task has been blocked the longest?"
            ),
            TaskChatStarterPrompt(
                id: "average-close-time",
                title: String(localized: "What is my average close time?"),
                requestText: "What is my average close time?"
            ),
            TaskChatStarterPrompt(
                id: "close-time-table",
                title: String(localized: "Show me my close time trend table"),
                requestText: "Show me my close time trend table"
            ),
            TaskChatStarterPrompt(
                id: "priority-close-time-chart",
                title: String(localized: "Show me a priority close-time chart"),
                requestText: "Show me a priority close-time chart"
            ),
            TaskChatStarterPrompt(
                id: "month-comparison-chart",
                title: String(localized: "Compare this month with last month in a chart"),
                requestText: "Compare this month with last month in a chart"
            ),
            TaskChatStarterPrompt(
                id: "blocked-age-chart",
                title: String(localized: "Show me blocked tasks by age chart"),
                requestText: "Show me blocked tasks by age chart"
            ),
            TaskChatStarterPrompt(
                id: "closed-last-seven-days",
                title: String(localized: "How many tasks did I close in the last 7 days?"),
                requestText: "How many tasks did I close in the last 7 days?"
            ),
            TaskChatStarterPrompt(
                id: "fastest-priority",
                title: String(localized: "Which priority closes fastest?"),
                requestText: "Which priority closes fastest?"
            )
        ]
    }
}
