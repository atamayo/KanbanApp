# KanbanApp - Technical Documentation

A modern, SwiftUI-based Kanban board application for iOS and macOS, utilizing **SwiftData** for persistence and a highly customized design system.

## Project Overview

- **Core Tech:** Swift 5.10+, SwiftUI, SwiftData.
- **Architecture:** MVVM-like pattern where SwiftUI views interact directly with SwiftData's `ModelContext` via the environment.
- **Persistence:** Local storage using the `@Model` macro for the `TaskItem` class.

## Project Structure

- `KanbanApp/`: Main application source code.
    - `KanbanApp.swift`: Entry point, initializes the `ModelContainer`.
    - `Models/`: Data models and enums.
        - `TaskItem.swift`: The primary SwiftData model.
    - `Views/`: SwiftUI components.
        - `KanbanBoardView.swift`: The main board with horizontal scrolling columns.
        - `KanbanColumnView.swift`: Represents a single status (e.g., "To Do").
        - `TaskCardView.swift`: Visual representation of a single task.
    - `AppStyle.swift`: Centralized design system (Colors, Typography, Spacing, Shapes).

## Building and Running

1.  **Xcode:** Open `KanbanApp.xcodeproj`.
2.  **Target:** Select an iOS Simulator (e.g., iPhone 15) or "My Mac".
3.  **Run:** Press `Cmd + R` or the Play button in Xcode.

*Note: No external package managers (CocoaPods/Carthage) are used. Any dependencies are managed via Swift Package Manager within the Xcode project.*

## Development Conventions

### Data Model (`TaskItem`)
- **Status & Priority:** Stored as raw strings (`statusRaw`, `priorityRaw`) to ensure SwiftData compatibility, but should **always** be accessed via the computed properties `.status` and `.priority` which bridge to the `TaskStatus` and `TaskPriority` enums.
- **Manual Ordering:** Tasks have an `order` property. Re-ordering logic is handled in `KanbanBoardView.swift` via the `reorder(status:)` function.

### Styling (`AppStyle`)
- **Strict Adherence:** Avoid hardcoded values. Use `AppStyle.Colors`, `AppStyle.Typography`, `AppStyle.Spacing`, and `AppStyle.Shapes`.
- **Dynamic Colors:** Most colors in `AppStyle` are defined with light/dark mode variations using `UIColor { ... }`.

### Views
- **Previews:** Every view should include a `#Preview` block, ideally injecting a mock `ModelContainer` if data is required.
- **Drag & Drop:** Implementation uses `.onDrag` and `.dropDestination`. Moving a task updates its `status`, `priority`, and `order`.

## Roadmap / Missing Features
- [ ] Unit and UI Tests.
- [ ] Linting (e.g., SwiftLint).
- [ ] CI/CD configuration.
- [ ] iCloud synchronization via CloudKit.
