# KanbanApp

A modern, high-performance Personal Kanban application for iOS and macOS, built with **SwiftUI** and **SwiftData**. This app is designed to help individuals visualize their work, limit work in progress (WIP), and maintain a steady flow of completion.

## 🚀 Features

- **Visual Kanban Board:** A fluid, horizontal-scrolling board to manage tasks across "To Do", "In Progress", and "Done" states.
- **Flow Optimization (Focus Guard):** Built-in system to prevent over-commitment by limiting the number of active tasks in the "In Progress" lane.
- **Rich Dashboard:** At-a-glance metrics including cycle time trends, priority distribution, and "Done Momentum".
- **Advanced Task Management:** Support for detailed descriptions, explicit "Definition of Done" (Completion Criteria), and task prioritization.
- **Local Persistence:** Powered by SwiftData for seamless, high-performance data management.
- **Custom Design System:** A meticulously crafted UI using a centralized `AppStyle` for consistent colors, typography, and motion.
- **Search:** Quickly find tasks across all statuses.
- **Onboarding:** A guided experience explaining the core principles of Personal Kanban.

## 🛠 Tech Stack

- **Language:** Swift 5.10+
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Platform Support:** iOS 17.0+, macOS 14.0+

## 📁 Project Structure

- `KanbanApp/`
    - `Models/`: SwiftData models (`TaskItem`) and core enums.
    - `Views/`: Modular SwiftUI views (Dashboard, Board, Search, Settings).
    - `Services/`: Logic for task generation and suggestions.
    - `AppStyle.swift`: Centralized design system configuration.
    - `KanbanApp.swift`: App entry point and `ModelContainer` initialization.

## 🏁 Getting Started

### Prerequisites

- Mac with **Xcode 15.0** or later.
- macOS Sonoma or later (for development and running on Mac).
- iOS 17.0+ (for running on iPhone/iPad).

### Building and Running

1.  Clone the repository or download the source code.
2.  Open `KanbanApp.xcodeproj` in Xcode.
3.  Select a target (e.g., iPhone 15 Pro simulator or "My Mac").
4.  Press `Cmd + R` to build and run the application.

### App Store Screenshot Scenes

Launch the app with `--app-store-screenshot=<scene>` to render a screenshot-only scene. Available scenes are `dashboard`, `board`, `quickCapture`, `focusGuard`, `flowReview`, `search`, and `wipChat`.

Export the WIP Chat scene as `07-wip-chat.png` in each existing `AppStoreScreenshots` device or locale folder.

## 📖 Development Conventions

- **Styling:** Always use `AppStyle` for colors, spacing, and typography. Avoid hardcoding magic numbers or colors.
- **Data Access:** Interact with `TaskItem` via its computed properties (`.status`, `.priority`) to ensure consistency with the underlying raw storage.
- **Previews:** Every view includes a `#Preview` block with mock data for rapid UI iteration.
- **Flow Control:** Respect the "Focus Guard" logic when implementing new ways to transition tasks into the "In Progress" state.

## 🗺 Roadmap

- [ ] iCloud Synchronization (CloudKit).
- [ ] Unit and UI Testing suite.
- [ ] Localization support.
- [ ] Custom status columns.
- [ ] Home Screen Widgets for WIP tracking.

---

*Built with ❤️ for focused workflows.*
