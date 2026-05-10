import SwiftUI

struct SettingsView: View {
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = true
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3
    @AppStorage("wipLimitHitCount") private var wipLimitHitCount = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                focusGuardHero
                flowOptimizationSection
                workflowPolicySection
                learningSection
            }
            .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
            .padding(.top, AppStyle.Spacing.outerVertical)
            .padding(.bottom, 120)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppStyle.Colors.Status.inProgress.opacity(0.14))
                        .frame(width: 48, height: 48)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.Status.inProgress)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Protect your attention")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Personal Kanban works best when you finish before you pull. Keep your active lane small and visible.")
                        .font(AppStyle.Typography.formFooter)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                settingsStatCard(
                    label: "Flow Optimization",
                    value: isFocusGuardEnabled ? "On" : "Off",
                    tint: isFocusGuardEnabled ? AppStyle.Colors.Status.done : .secondary
                )

                settingsStatCard(
                    label: "WIP Limit",
                    value: "\(maxActiveTasks)",
                    tint: AppStyle.Colors.Status.inProgress
                )
            }
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppStyle.Colors.Status.inProgress.opacity(0.14),
                            AppStyle.Colors.surface,
                            AppStyle.Colors.surface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: 1)
        }
    }

    private var flowOptimizationSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Flow Optimization")

            VStack(alignment: .leading, spacing: 18) {
                Toggle(isOn: $isFocusGuardEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "scope")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppStyle.Colors.Status.inProgress)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Flow Optimization")
                                .font(AppStyle.Typography.statusLabelHighlighted)
                                .foregroundStyle(.primary)

                            Text("Limit work in progress to reduce context switching.")
                                .font(AppStyle.Typography.cardDate)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(AppStyle.Colors.Status.inProgress)

                if isFocusGuardEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Max Active Tasks", systemImage: "gauge.medium")
                                .font(AppStyle.Typography.statusLabel)
                                .foregroundStyle(.primary)

                            Spacer()

                            Text("\(maxActiveTasks)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppStyle.Colors.Status.inProgress)
                        }

                        Stepper("", value: $maxActiveTasks, in: 1...5)
                            .labelsHidden()

                        Text(recommendationText)
                            .font(AppStyle.Typography.guidanceFooter)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(AppStyle.Colors.Status.inProgress.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(20)
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
    }

    private var learningSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Practice")

            VStack(spacing: 14) {
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

            VStack(spacing: 14) {
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

    private func settingsStatCard(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func settingsLinkCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppStyle.Colors.Status.todo.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.Status.todo)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }

    private func settingsInfoCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.Status.done)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(.primary)

                Text(body)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(18)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppStyle.Typography.statusLabel)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(AppStyle.Typography.statusLabelHighlighted)
                .foregroundStyle(.primary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppStyle.Typography.sectionTitle)
            .foregroundStyle(.secondary)
            .tracking(AppStyle.Typography.sectionTracking)
    }
}
