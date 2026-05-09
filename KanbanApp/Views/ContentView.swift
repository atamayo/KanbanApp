import SwiftUI

struct ContentView: View {
    var body: some View {
        KanbanBoardView()
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}
