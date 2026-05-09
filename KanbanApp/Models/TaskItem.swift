import Foundation
import SwiftData

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"

    var id: String { rawValue }
}

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var desc: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    var order: Int

    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .todo }
        set { statusRaw = newValue.rawValue }
    }

    init(title: String, description: String = "", status: TaskStatus = .todo, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.desc = description
        self.statusRaw = status.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.order = order
    }
}
