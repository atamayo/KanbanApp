import SwiftUI

struct SettingsView: View {
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0
    @AppStorage("isTaskAgingNotificationsEnabled") private var isTaskAgingNotificationsEnabled = false
    @AppStorage("taskAgingNotificationDayThreshold") private var taskAgingNotificationDayThreshold = 3
    @AppStorage("taskStalledNotificationDayThreshold") private var taskStalledNotificationDayThreshold = 5
    @AppStorage("taskAgingNotificationHour") private var taskAgingNotificationHour = 9
    @Environment(\.persistenceSyncMode) private var persistenceSyncMode
    @State private var taskAgingNotificationMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                focusGuardHero
                syncSection
                flowOptimizationSection
                taskAgingNotificationSection
                workflowPolicySection
                learningSection
            }
            .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
            .padding(.top, AppStyle.Spacing.outerVertical)
            .padding(.bottom, AppStyle.Spacing.settingsBottomPadding)
        }
        .background(AppStyle.Colors.background)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .contentMargins(.top, AppStyle.Spacing.small, for: .scrollContent)
        .contentMargins(.bottom, AppStyle.Spacing.extraLarge, for: .scrollContent)
        .controlSize(.large)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var focusGuardHero: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.regular) {
            HStack(alignment: .top, spacing: AppStyle.Spacing.regular) {
                ZStack {
                    Circle()
                        .fill(AppStyle.Colors.Status.inProgress.opacity(AppStyle.Opacity.accentWashEmphasized))
                        .frame(width: AppStyle.Shapes.iconBadgeMedium, height: AppStyle.Shapes.iconBadgeMedium)

                    Image(systemName: "brain.head.profile")
                        .font(AppStyle.Typography.iconLarge)
                        .foregroundStyle(AppStyle.Colors.Status.inProgress)
                }

                VStack(alignment: .leading, spacing: AppStyle.Spacing.tight) {
                    Text("Protect your attention")
                        .font(AppStyle.Typography.metricMedium)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Text("Personal Kanban works best when you finish before you pull. Keep your active lane small and visible.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(AppStyle.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                settingsStatCard(
                    label: "Flow Optimization",
                    value: isFocusGuardEnabled ? String(localized: "On") : String(localized: "Off"),
                    tint: isFocusGuardEnabled ? AppStyle.Colors.Status.done : AppStyle.Colors.secondaryText
                )

                settingsStatCard(
                    label: "WIP Limit",
                    value: "\(maxActiveTasks)",
                    tint: AppStyle.Colors.Status.inProgress
                )
            }
        }
        .padding(AppStyle.Spacing.heroPadding)
        .accentCardStyle(tint: AppStyle.Colors.Status.inProgress)
    }

    private var flowOptimizationSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Flow Optimization")

            VStack(alignment: .leading, spacing: AppStyle.Spacing.comfortable) {
                Toggle(isOn: $isFocusGuardEnabled) {
                    HStack(spacing: AppStyle.Spacing.statusRowGap) {
                        Image(systemName: "scope")
                            .font(AppStyle.Typography.iconMedium)
                            .foregroundStyle(AppStyle.Colors.Status.inProgress)
                            .frame(width: AppStyle.Spacing.iconFrameWidthLarge)

                        VStack(alignment: .leading, spacing: AppStyle.Spacing.micro) {
                            Text("Enable Flow Optimization")
                                .font(AppStyle.Typography.statusLabelHighlighted)
                                .foregroundStyle(AppStyle.Colors.primaryText)

                            Text("Limit work in progress to reduce context switching.")
                                .font(AppStyle.Typography.cardDate)
                                .foregroundStyle(AppStyle.Colors.secondaryText)
                        }
                    }
                }
                .tint(AppStyle.Colors.Status.inProgress)

                if isFocusGuardEnabled {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.statusRowGap) {
                        HStack {
                            Label("Max Active Tasks", systemImage: "gauge.medium")
                                .font(AppStyle.Typography.statusLabel)
                                .foregroundStyle(AppStyle.Colors.primaryText)

                            Spacer()

                            Text("\(maxActiveTasks)")
                                .font(AppStyle.Typography.metricMedium)
                                .foregroundStyle(AppStyle.Colors.Status.inProgress)
                        }

                        Stepper("", value: $maxActiveTasks, in: 1...5)
                            .labelsHidden()

                        Text(recommendationText)
                            .font(AppStyle.Typography.guidanceFooter)
                            .foregroundStyle(AppStyle.Colors.secondaryText)
                    }
                    .padding(AppStyle.Spacing.normal)
                    .background(AppStyle.Colors.Status.inProgress.opacity(AppStyle.Opacity.accentWashSubtle), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                }
            }
            .padding(AppStyle.Spacing.large)
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Task Sync")

            settingsInfoCard(
                icon: persistenceSyncMode.isCloudBacked ? "icloud.fill" : "internaldrive.fill",
                title: persistenceSyncMode.isCloudBacked ? "iCloud sync is on" : "Using local storage on this device",
                body: persistenceSyncMode.isCloudBacked
                    ? "Tasks sync through iCloud when you use the same Apple Account on each device. Changes can take a short moment to appear everywhere."
                    : "Tasks are currently stored only on this device. Turn on iCloud for this app to keep tasks available when you switch phones."
            )
        }
    }

    private var taskAgingNotificationSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Active Task Nudges")

            VStack(alignment: .leading, spacing: AppStyle.Spacing.comfortable) {
                Toggle(isOn: taskAgingNotificationToggleBinding) {
                    HStack(spacing: AppStyle.Spacing.statusRowGap) {
                        Image(systemName: "bell.badge.fill")
                            .font(AppStyle.Typography.iconMedium)
                            .foregroundStyle(AppStyle.Colors.warning)
                            .frame(width: AppStyle.Spacing.iconFrameWidthLarge)

                        VStack(alignment: .leading, spacing: AppStyle.Spacing.micro) {
                            Text("Enable Active Task Nudges")
                                .font(AppStyle.Typography.statusLabelHighlighted)
                                .foregroundStyle(AppStyle.Colors.primaryText)

                            Text("Send one daily reminder when In Progress tasks are aging or stalled.")
                                .font(AppStyle.Typography.cardDate)
                                .foregroundStyle(AppStyle.Colors.secondaryText)
                        }
                    }
                }
                .tint(AppStyle.Colors.warning)

                if isTaskAgingNotificationsEnabled {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.statusRowGap) {
                        thresholdStepper(
                            title: "Aging after",
                            value: taskAgingNotificationDayThreshold,
                            systemImage: "clock.badge.exclamationmark",
                            binding: agingThresholdBinding,
                            range: 1...14
                        )

                        thresholdStepper(
                            title: "Stalled after",
                            value: taskStalledNotificationDayThreshold,
                            systemImage: "exclamationmark.circle.fill",
                            binding: stalledThresholdBinding,
                            range: (taskAgingNotificationDayThreshold + 1)...30
                        )

                        infoRow(label: "Digest time", value: "\(taskAgingNotificationHour):00")

                        Text("The app schedules a rolling daily digest at \(taskAgingNotificationHour):00 and never sends one notification per task.")
                            .font(AppStyle.Typography.guidanceFooter)
                            .foregroundStyle(AppStyle.Colors.secondaryText)
                    }
                    .padding(AppStyle.Spacing.normal)
                    .background(AppStyle.Colors.warning.opacity(AppStyle.Opacity.accentWashSubtle), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                }

                if let taskAgingNotificationMessage {
                    Text(taskAgingNotificationMessage)
                        .font(AppStyle.Typography.guidanceFooter)
                        .foregroundStyle(AppStyle.Colors.warning)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppStyle.Spacing.large)
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
    }

    private var learningSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Practice")

            VStack(spacing: AppStyle.Spacing.regular) {
                NavigationLink {
                    PersonalKanbanManifestoView()
                } label: {
                    settingsLinkCard(
                        icon: "book.pages.fill",
                        title: "Personal Kanban Manifesto",
                        subtitle: "Read the core principles behind visual work, pull systems, and WIP limits."
                    )
                }
                .buttonStyle(.plain)

                settingsInfoCard(
                    icon: "checkmark.circle",
                    title: "Small WIP, faster finish",
                    body: "A limit of 2 or 3 active tasks usually improves focus, quality, and completion rate."
                )
            }
        }
    }

    private var workflowPolicySection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Workflow Policy")

            VStack(spacing: AppStyle.Spacing.regular) {
                settingsInfoCard(
                    icon: "arrow.down.circle.fill",
                    title: "Pull only when there is room",
                    body: "In this app, a new task should move into In Progress only when the active lane has capacity. WIP limit hits so far: \(wipLimitHitCount)."
                )

                settingsInfoCard(
                    icon: "bolt.circle.fill",
                    title: "In Progress means active attention",
                    body: "A task belongs in In Progress only when you are actively working it now. Blocked or waiting work should be visible, not mixed in silently."
                )

                settingsInfoCard(
                    icon: "checkmark.circle.fill",
                    title: "Done means criteria met",
                    body: "A task is done when its finish check is satisfied, not when it merely feels close. Use the Definition of Done field to make completion explicit."
                )
            }
        }
    }

    private var recommendationText: String {
        switch maxActiveTasks {
        case 1:
            return "Single-task mode. Maximum focus, minimum switching."
        case 2...3:
            return "Recommended range for Personal Kanban. Tight enough to stay focused, flexible enough to keep moving."
        default:
            return "Higher limits increase context switching. Use only if your workflow truly requires it."
        }
    }

    private var taskAgingNotificationToggleBinding: Binding<Bool> {
        Binding(
            get: { isTaskAgingNotificationsEnabled },
            set: { newValue in
                Task {
                    await updateTaskAgingNotificationsEnabled(newValue)
                }
            }
        )
    }

    private var agingThresholdBinding: Binding<Int> {
        Binding(
            get: { taskAgingNotificationDayThreshold },
            set: { newValue in
                taskAgingNotificationDayThreshold = max(newValue, 1)
                if taskStalledNotificationDayThreshold <= taskAgingNotificationDayThreshold {
                    taskStalledNotificationDayThreshold = taskAgingNotificationDayThreshold + 1
                }
            }
        )
    }

    private var stalledThresholdBinding: Binding<Int> {
        Binding(
            get: { taskStalledNotificationDayThreshold },
            set: { newValue in
                taskStalledNotificationDayThreshold = max(newValue, taskAgingNotificationDayThreshold + 1)
            }
        )
    }

    @MainActor
    private func updateTaskAgingNotificationsEnabled(_ isEnabled: Bool) async {
        taskAgingNotificationMessage = nil

        guard isEnabled else {
            isTaskAgingNotificationsEnabled = false
            await TaskAgingNotificationService.cancelScheduledNotifications()
            return
        }

        let granted = await TaskAgingNotificationService.requestAuthorization()
        if granted {
            isTaskAgingNotificationsEnabled = true
        } else {
            isTaskAgingNotificationsEnabled = false
            taskAgingNotificationMessage = String(localized: "Notifications were not enabled. You can allow them in Settings to receive active task nudges.")
            await TaskAgingNotificationService.cancelScheduledNotifications()
        }
    }

    private func settingsStatCard(label: LocalizedStringKey, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            Text(label)
                .font(AppStyle.Typography.statLabel)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Text(value)
                .font(AppStyle.Typography.metricMedium)
                .foregroundStyle(tint)
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(AppStyle.Opacity.accentWashSubtle), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
    }

    private func settingsLinkCard(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: AppStyle.Spacing.regular) {
            ZStack {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                    .fill(AppStyle.Colors.Status.todo.opacity(AppStyle.Opacity.accentWashStrong))
                    .frame(width: AppStyle.Shapes.iconBadgeMedium, height: AppStyle.Shapes.iconBadgeMedium)

                Image(systemName: icon)
                    .font(AppStyle.Typography.iconMedium)
                    .foregroundStyle(AppStyle.Colors.Status.todo)
            }

            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                Text(title)
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(AppStyle.Colors.primaryText)

                Text(subtitle)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AppStyle.Typography.iconSmall)
                .foregroundStyle(AppStyle.Colors.tertiaryText)
        }
        .padding(AppStyle.Spacing.cardContentPadding)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }

    private func thresholdStepper(
        title: LocalizedStringKey,
        value: Int,
        systemImage: String,
        binding: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(AppStyle.Typography.statusLabel)
                    .foregroundStyle(AppStyle.Colors.primaryText)

                Spacer()

                Text(String(localized: "\(value) \(value == 1 ? String(localized: "day") : String(localized: "days"))"))
                    .font(AppStyle.Typography.metricMedium)
                    .foregroundStyle(AppStyle.Colors.warning)
            }

            Stepper("", value: binding, in: range)
                .labelsHidden()
        }
    }

    private func settingsInfoCard(icon: String, title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.regular) {
            Image(systemName: icon)
                .font(AppStyle.Typography.iconMedium)
                .foregroundStyle(AppStyle.Colors.Status.done)
                .frame(width: AppStyle.Spacing.iconFrameWidthMedium)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                Text(title)
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(AppStyle.Colors.primaryText)

                Text(body)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(AppStyle.Spacing.cardContentPadding)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }

    private func infoRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppStyle.Typography.statusLabel)
                .foregroundStyle(AppStyle.Colors.secondaryText)

            Spacer()

            Text(value)
                .font(AppStyle.Typography.statusLabelHighlighted)
                .foregroundStyle(AppStyle.Colors.primaryText)
        }
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .sectionHeaderStyle()
    }
}
