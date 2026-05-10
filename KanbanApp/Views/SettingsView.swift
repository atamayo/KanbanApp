import SwiftUI

struct SettingsView: View {
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3

    var body: some View {
        List {
            Section {
                Toggle(isOn: $isFocusGuardEnabled) {
                    Label("Enable Focus Guard", systemImage: "boundary.navigational.right.fill")
                }
                
                if isFocusGuardEnabled {
                    Stepper(value: $maxActiveTasks, in: 1...5) {
                        HStack {
                            Label("Max Active Tasks", systemImage: "gauge.medium")
                            Spacer()
                            Text("\(maxActiveTasks)")
                                .fontWeight(.bold)
                                .foregroundStyle(AppStyle.Colors.Status.inProgress)
                        }
                    }
                }
            } header: {
                Text("Flow Optimization")
            } footer: {
                Text("Personal Kanban recommends a WIP limit of 2 or 3 to minimize context-switching and finish tasks faster.")
                    .font(AppStyle.Typography.guidanceFooter)
                    .foregroundStyle(.secondary)
                    .padding(.top, AppStyle.Spacing.tiny)
            }

            Section {
                Label("Appearance", systemImage: "paintbrush")
                Label("Notifications", systemImage: "bell")
                Label("Data Management", systemImage: "tray")
            } header: {
                Text("Preferences")
            }

            Section {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
