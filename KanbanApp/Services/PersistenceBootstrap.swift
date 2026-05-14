import OSLog
import SwiftData
import SwiftUI

enum PersistenceSyncMode: Sendable {
    case cloudKit
    case localFallback

    var isCloudBacked: Bool {
        self == .cloudKit
    }
}

struct PersistenceBootstrapResult {
    let container: ModelContainer
    let syncMode: PersistenceSyncMode
}

enum PersistenceBootstrap {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "KanbanApp",
        category: "Persistence"
    )

    static func makeContainer() -> PersistenceBootstrapResult {
        do {
            let cloudConfiguration = ModelConfiguration(cloudKitDatabase: .automatic)
            let container = try ModelContainer(for: TaskItem.self, configurations: cloudConfiguration)

            logger.info("Using CloudKit-backed SwiftData store.")
            return PersistenceBootstrapResult(container: container, syncMode: .cloudKit)
        } catch {
            logger.error("Falling back to local SwiftData store: \(error.localizedDescription, privacy: .public)")

            do {
                let localConfiguration = ModelConfiguration()
                let container = try ModelContainer(for: TaskItem.self, configurations: localConfiguration)
                return PersistenceBootstrapResult(container: container, syncMode: .localFallback)
            } catch {
                fatalError("Unable to create any SwiftData store: \(error.localizedDescription)")
            }
        }
    }
}

private struct PersistenceSyncModeKey: EnvironmentKey {
    static let defaultValue: PersistenceSyncMode = .localFallback
}

extension EnvironmentValues {
    var persistenceSyncMode: PersistenceSyncMode {
        get { self[PersistenceSyncModeKey.self] }
        set { self[PersistenceSyncModeKey.self] = newValue }
    }
}
