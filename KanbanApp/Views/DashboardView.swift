import SwiftUI
struct DashboardView: View {
    let allTasks: [TaskItem]
    var onAddTask: (() -> Void)? = nil
    var onSelectStatus: ((TaskStatus) -> Void)? = nil
    
    @AppStorage("isFocusGuardEnabled") private var isFocusGuardEnabled = false
    @AppStorage("maxActiveTasks") private var maxActiveTasks = 3

    // MARK: - Data

    private var totalCount: Int { allTasks.count }
    private var doneCount: Int { allTasks.filter { $0.status == .done }.count }
    private var inProgressCount: Int { allTasks.filter { $0.status == .inProgress }.count }
    private var todoCount: Int { allTasks.filter { $0.status == .todo }.count }

    private var donePercent: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }

    private func count(priority: TaskPriority) -> Int {
        allTasks.filter { $0.priority == priority }.count
    }

    private var recentTasks: [TaskItem] {
        allTasks.sorted { $0.updatedAt > $1.updatedAt }.prefix(3).map { $0 }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if allTasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppStyle.Spacing.compactSectionSpacing) {
                    headerSection
                    statusSection
                    prioritySection
                    
                    if !recentTasks.isEmpty {
                        recentActivitySection
                    }
                    
                    insightFooter
                }
                .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
                .padding(.vertical, AppStyle.Spacing.outerVertical)
            }
        }
        .background(AppStyle.Colors.background)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onAddTask?()
                } label: {
                    Image(systemName: "plus")
                        .font(AppStyle.Typography.bodyLarge)
                        .foregroundStyle(AppStyle.Colors.Status.todo)
                        .frame(width: AppStyle.Shapes.buttonSizeMedium, height: AppStyle.Shapes.buttonSizeMedium)
                        .background(.ultraThinMaterial, in: .circle)
                        .overlay(
                            Circle()
                                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                        )
                        .shadow(color: AppStyle.Colors.cardShadow, radius: AppStyle.Shapes.cardShadowRadius, x: 0, y: 2)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Image(systemName: "square.3.layers.3d")
                .font(AppStyle.Typography.emptyIcon)
                .foregroundStyle(.secondary)

            Text("No tasks yet")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(.primary)

            Text("Add a task to populate your dashboard")
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppStyle.Spacing.emptyStateVerticalPadding)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: AppStyle.Spacing.hStackGap) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.headerVStackGap) {
                Text("Your Progress")
                    .font(AppStyle.Typography.sectionTitle)
                    .foregroundStyle(.secondary)
                    .tracking(AppStyle.Typography.sectionTracking)
                
                Text("\(doneCount) of \(totalCount) tasks")
                    .font(AppStyle.Typography.compactHeaderTitle)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }

            Spacer()
            
            progressRing
        }
        .padding(.vertical, AppStyle.Spacing.headerPaddingVertical)
        .padding(.horizontal, AppStyle.Spacing.headerPaddingHorizontal)
        .cardStyle(cornerRadius: AppStyle.Shapes.headerCornerRadius)
    }

    private var progressRing: some View {
        let ringSize = AppStyle.Shapes.compactRingSize
        return ZStack {
            Circle()
                .stroke(AppStyle.Colors.track, lineWidth: AppStyle.Shapes.compactRingTrackStroke)

            Circle()
                .trim(from: 0, to: donePercent)
                .stroke(
                    AppStyle.Colors.Status.done.opacity(0.25),
                    style: .init(lineWidth: AppStyle.Shapes.compactRingGlowStroke, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: AppStyle.Shapes.compactRingGlowBlur)

            Circle()
                .trim(from: 0, to: donePercent)
                .stroke(
                    LinearGradient(
                        colors: [AppStyle.Colors.Status.done, AppStyle.Colors.Status.done.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: .init(lineWidth: AppStyle.Shapes.compactRingTrackStroke, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 1, bounce: 0.15), value: donePercent)

            Text("\(Int(donePercent * 100))%")
                .font(AppStyle.Typography.ringPercentageSmall)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
        .frame(width: ringSize, height: ringSize)
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.statusRowGap) {
            HStack(alignment: .center) {
                sectionHeader("Status")
                Spacer()
                stackedBar
                    .frame(width: AppStyle.Spacing.stackedBarWidth)
            }

            VStack(spacing: AppStyle.Spacing.none) {
                statusRow(status: .todo, count: todoCount, color: AppStyle.Colors.Status.todo, icon: "circle")
                
                dividerLine
                
                statusRow(status: .inProgress, count: inProgressCount, color: AppStyle.Colors.Status.inProgress, icon: "clock.fill", isHighlighted: true)
                
                dividerLine
                
                statusRow(status: .done, count: doneCount, color: AppStyle.Colors.Status.done, icon: "checkmark.circle.fill")
            }
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
    }

    private var dividerLine: some View {
        AppStyle.Colors.divider
            .frame(height: 1)
            .padding(.leading, AppStyle.Spacing.dividerLeadingCompact)
    }

    private func statusRow(status: TaskStatus, count: Int, color: Color, icon: String, isHighlighted: Bool = false) -> some View {
        let barRatio = totalCount > 0 ? Double(count) / Double(totalCount) : 0.0
        
        // Focus Guard logic
        let isWIPLimitReached = isFocusGuardEnabled && status == .inProgress && count >= maxActiveTasks
        let rowColor = isWIPLimitReached ? AppStyle.Colors.warning : color

        return Button {
            onSelectStatus?(status)
        } label: {
            HStack(spacing: AppStyle.Spacing.statusRowGap) {
                Image(systemName: isWIPLimitReached ? "exclamationmark.triangle.fill" : icon)
                    .font(.system(size: AppStyle.Shapes.statusIconSize, weight: .bold))
                    .foregroundStyle(rowColor)
                    .frame(width: AppStyle.Spacing.statusIconWidth)

                Text(status.rawValue)
                    .font(isHighlighted ? AppStyle.Typography.statusLabelHighlighted : AppStyle.Typography.statusLabel)
                    .foregroundStyle(isHighlighted ? .primary : rowColor.opacity(0.85))
                    .frame(width: AppStyle.Spacing.statusLabelWidthCompact, alignment: .leading)

                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [rowColor, rowColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(AppStyle.Shapes.minBarWidth, geo.size.width * barRatio))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: barRatio)
                }
                .frame(height: isHighlighted ? AppStyle.Shapes.barHeightHighlighted : AppStyle.Shapes.barHeight)

                Text(count.formatted())
                    .font(isHighlighted ? AppStyle.Typography.statusLabelHighlighted : AppStyle.Typography.statusCount)
                    .foregroundStyle(isHighlighted ? .primary : .secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .frame(width: AppStyle.Spacing.statusCountWidthCompact, alignment: .trailing)
            }
            .padding(.horizontal, AppStyle.Spacing.cardPadding)
            .padding(.vertical, isHighlighted ? AppStyle.Spacing.statusRowVerticalHighlighted : AppStyle.Spacing.statusRowVerticalCompact)
            .contentShape(.rect)
            .background {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.statusHighlightCornerRadius, style: .continuous)
                        .fill(rowColor.opacity(0.12))
                        .padding(.horizontal, AppStyle.Spacing.statusHighlightPaddingHorizontal)
                        .padding(.vertical, AppStyle.Spacing.statusHighlightPaddingVertical)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(status.rawValue), \(count) tasks")
    }

    private var stackedBar: some View {
        let total = max(totalCount, 1)
        let todoRatio = CGFloat(todoCount) / CGFloat(total)
        let progRatio = CGFloat(inProgressCount) / CGFloat(total)
        let doneRatio = CGFloat(doneCount) / CGFloat(total)

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppStyle.Colors.track)

                HStack(spacing: AppStyle.Spacing.none) {
                    if todoCount > 0 {
                        Rectangle()
                            .fill(AppStyle.Colors.Status.todo)
                            .frame(width: geo.size.width * todoRatio)
                    }
                    if inProgressCount > 0 {
                        Rectangle()
                            .fill(isFocusGuardEnabled && inProgressCount >= maxActiveTasks ? AppStyle.Colors.warning : AppStyle.Colors.Status.inProgress)
                            .frame(width: geo.size.width * progRatio)
                    }
                    if doneCount > 0 {
                        Rectangle()
                            .fill(AppStyle.Colors.Status.done)
                            .frame(width: geo.size.width * doneRatio)
                    }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: AppStyle.Shapes.barHeight)
    }

    // MARK: - Priority

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Priority")

            HStack(spacing: AppStyle.Spacing.priorityHStackGap) {
                priorityCard(priority: "High", count: count(priority: .high), tint: AppStyle.Colors.Priority.high)
                priorityCard(priority: "Medium", count: count(priority: .medium), tint: AppStyle.Colors.Priority.medium)
                priorityCard(priority: "Low", count: count(priority: .low), tint: AppStyle.Colors.Priority.low)
            }
        }
    }

    private func priorityCard(priority: String, count: Int, tint: Color) -> some View {
        let isEmpty = count == 0
        
        return VStack(spacing: AppStyle.Spacing.none) {
            tint
                .frame(height: AppStyle.Shapes.accentBarHeight)
                .opacity(isEmpty ? 0.3 : 1.0)

            VStack(spacing: AppStyle.Spacing.priorityCardVStackGap) {
                Text(count.formatted())
                    .font(AppStyle.Typography.priorityNumber)
                    .foregroundStyle(isEmpty ? .tertiary : .primary)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: AppStyle.Spacing.sectionHStackGap) {
                    Circle()
                        .fill(isEmpty ? .secondary.opacity(0.3) : tint)
                        .frame(width: AppStyle.Shapes.priorityDotSize, height: AppStyle.Shapes.priorityDotSize)
                    Text(priority)
                        .font(AppStyle.Typography.priorityLabelBold)
                        .foregroundStyle(isEmpty ? .tertiary : .primary)
                }
            }
            .padding(.vertical, AppStyle.Spacing.priorityVerticalPadding)
            .padding(.horizontal, AppStyle.Spacing.statusRowVerticalCompact)
        }
        .frame(maxWidth: .infinity)
        .background(isEmpty ? Color.secondary.opacity(0.02) : Color.clear)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        .opacity(isEmpty ? 0.8 : 1.0)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.sectionToCard) {
            sectionHeader("Recent Activity")

            VStack(spacing: AppStyle.Spacing.none) {
                ForEach(recentTasks) { task in
                    HStack(alignment: .top, spacing: AppStyle.Spacing.statusRowGap) {
                        Circle()
                            .fill(statusColor(for: task.status))
                            .frame(width: AppStyle.Shapes.dotSize, height: AppStyle.Shapes.dotSize)
                            .padding(.top, AppStyle.Spacing.recentActivityCircleTopPadding)
                        
                        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                            Text(task.title)
                                .font(AppStyle.Typography.cardTitle)
                                .foregroundStyle(.primary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                            
                            Text(task.updatedAt, style: .relative)
                                .font(AppStyle.Typography.cardDate)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppStyle.Spacing.cardPadding)
                    .padding(.vertical, AppStyle.Spacing.recentActivityRowVerticalPadding)
                    
                    if task.id != recentTasks.last?.id {
                        AppStyle.Colors.divider
                            .frame(height: 1)
                            .padding(.leading, AppStyle.Spacing.cardPadding + AppStyle.Spacing.statusIconWidth)
                    }
                }
            }
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
    }

    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo: return AppStyle.Colors.Status.todo
        case .inProgress: return AppStyle.Colors.Status.inProgress
        case .done: return AppStyle.Colors.Status.done
        }
    }

    // MARK: - Footer

    private var insightFooter: some View {
        VStack(spacing: AppStyle.Spacing.statusHighlightPaddingHorizontal) {
            Text("You've completed \(doneCount) tasks.")
                .font(AppStyle.Typography.formFooter)
                .foregroundStyle(.secondary)
            
            Text("Keep up the great momentum!")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppStyle.Spacing.normal)
        .padding(.bottom, AppStyle.Spacing.emptyBottomSpacer)
    }

    // MARK: - Shared

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppStyle.Typography.sectionTitle)
            .foregroundStyle(.secondary)
            .tracking(AppStyle.Typography.sectionTracking)
    }
}
