# KanbanApp

SwiftUI + SwiftData Kanban board (iOS/macOS).

## Project structure

- `KanbanApp.swift` — `@main` entrypoint, creates `ModelContainer(for: TaskItem.self)`
- `Models/TaskItem.swift` — SwiftData `@Model` with `statusRaw` string bridging to `TaskStatus` enum
- `Views/` — all views: board, columns, cards, add/edit sheets

## Key facts

- **`.xcodeproj` is committed.** Open `KanbanApp.xcodeproj` to work on the project. No `Package.swift` exists.
- **No test, lint, or CI configuration exists.**
- **SwiftData** persistence via `@Model` macro and `@Query` in `KanbanBoardView`. Model context is injected through the environment.
- **Drag-and-drop** between columns uses `.onDrag`/`.dropDestination` with `UUID` strings.
- **Task ordering** is manual: `order: Int` field, re-calculated after each move via `reorder()`.
- **Status enum** (`todo`, `inProgress`, `done`) stored as raw string in `statusRaw` — always access via computed `.status` property.
- **Localization is mandatory.** Any new user-facing text, controls, dialogs, accessibility labels/hints, placeholders, prompt starters, chart/table labels, and chat/system messages must be added to `KanbanApp/Resources/Localizable.xcstrings` and translated for every supported catalog locale (`ca`, `de`, `es-ES`, `fr-FR`, `hi`, `it`, `ja`, `ko`, `nl`, `pl`, `pt-BR`, `zh-Hans`). Keep `knownRegions` in `KanbanApp.xcodeproj/project.pbxproj` aligned with those locales.
- Initially created by an AI assistant (OpenCode).
