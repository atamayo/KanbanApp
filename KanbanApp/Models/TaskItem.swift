import Foundation
import SwiftData

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .todo: return 0
        case .inProgress: return 1
        case .done: return 2
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var desc: String
    var completionCriteria: String
    var statusRaw: String
    var priorityRaw: String?
    var isBlocked: Bool
    var createdAt: Date
    var updatedAt: Date
    var finalizedAt: Date?
    var enteredInProgressAt: Date?
    var order: Int

    var lastStatusChange: Date
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .todo }
        set { 
            if statusRaw != newValue.rawValue {
                statusRaw = newValue.rawValue 
                if newValue == .inProgress {
                    enteredInProgressAt = Date()
                } else if newValue == .todo {
                    enteredInProgressAt = nil
                }
                if newValue != .inProgress {
                    isBlocked = false
                }
                updateFinalizedAt(for: newValue)
                lastStatusChange = Date()
            }
        }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw ?? "") ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var isStale: Bool {
        status == .inProgress && Date().timeIntervalSince(lastStatusChange) > (3 * 24 * 60 * 60)
    }


    func timeInStatus() -> String {
        let diff = Date().timeIntervalSince(lastStatusChange)
// ...
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        let days = Int(diff / 86400)
        
        if days > 0 { return "\(days)d in status" }
        if hours > 0 { return "\(hours)h in status" }
        if minutes > 0 { return "\(minutes)m ago" }
        return ""
    }

    init(title: String, description: String = "", completionCriteria: String = "", status: TaskStatus = .todo, priority: TaskPriority = .medium, isBlocked: Bool = false, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.desc = description
        self.completionCriteria = completionCriteria
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.isBlocked = status == .inProgress ? isBlocked : false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastStatusChange = Date()
        self.enteredInProgressAt = status == .inProgress ? Date() : nil
        self.order = order
        updateFinalizedAt(for: status)
    }

    private func updateFinalizedAt(for status: TaskStatus) {
        if status == .done {
            if finalizedAt == nil {
                finalizedAt = Date()
            }
        } else {
            finalizedAt = nil
        }
    }
}
