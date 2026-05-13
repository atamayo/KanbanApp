import SwiftUI

enum AppStyle {

    // MARK: - Dynamic Color Helper

    private static func dynamic(dark: UIColor, light: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    // MARK: - Colors

    enum Colors {
        static let clear = Color.clear
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(uiColor: .tertiaryLabel)
        static let quaternaryText = Color(uiColor: .quaternaryLabel)
        static let inverseText = Color.white

        static let background = dynamic(
            dark: UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1),
            light: UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        )

        static let surface = Color(.secondarySystemBackground)

        static let surfaceBorder = dynamic(
            dark: UIColor(white: 1, alpha: 0.06),
            light: UIColor(white: 0, alpha: 0.08)
        )

        static let subtleText = secondaryText
        static let disabledControl = dynamic(
            dark: UIColor(white: 1, alpha: 0.22),
            light: UIColor(white: 0, alpha: 0.24)
        )
        static let scrim = dynamic(
            dark: UIColor(white: 0, alpha: 0.45),
            light: UIColor(white: 0, alpha: 0.35)
        )
        static let glassTint = dynamic(
            dark: UIColor(white: 1, alpha: 0.08),
            light: UIColor(white: 1, alpha: 0.12)
        )
        static let spotlightSurface = dynamic(
            dark: UIColor(white: 1, alpha: 0.08),
            light: UIColor(white: 1, alpha: 0.58)
        )

        enum Status {
            static let todo = dynamic(
                dark: UIColor(red: 0.35, green: 0.55, blue: 0.95, alpha: 1),
                light: UIColor(red: 0.20, green: 0.42, blue: 0.80, alpha: 1)
            )
            static let inProgress = dynamic(
                dark: UIColor(red: 0.90, green: 0.55, blue: 0.25, alpha: 1),
                light: UIColor(red: 0.85, green: 0.45, blue: 0.20, alpha: 1)
            )
            static let done = dynamic(
                dark: UIColor(red: 0.30, green: 0.75, blue: 0.55, alpha: 1),
                light: UIColor(red: 0.20, green: 0.60, blue: 0.40, alpha: 1)
            )
        }

        enum Priority {
            static let high = dynamic(
                dark: UIColor(red: 0.88, green: 0.35, blue: 0.38, alpha: 1),
                light: UIColor(red: 0.75, green: 0.25, blue: 0.28, alpha: 1)
            )
            static let medium = dynamic(
                dark: UIColor(red: 0.88, green: 0.70, blue: 0.34, alpha: 1),
                light: UIColor(red: 0.64, green: 0.49, blue: 0.18, alpha: 1)
            )
            static let low = dynamic(
                dark: UIColor(red: 0.48, green: 0.58, blue: 0.68, alpha: 1),
                light: UIColor(red: 0.34, green: 0.45, blue: 0.56, alpha: 1)
            )
        }

        enum Zone {
            static let high = AppStyle.Colors.Priority.high
            static let medium = AppStyle.Colors.secondaryText
            static let low = AppStyle.Colors.tertiaryText
            static let dropHighlight = dynamic(
                dark: UIColor(red: 1, green: 0, blue: 0, alpha: 0.1),
                light: UIColor(red: 1, green: 0, blue: 0, alpha: 0.06)
            )
        }

        static let divider = dynamic(
            dark: UIColor(white: 1, alpha: 0.04),
            light: UIColor(white: 0, alpha: 0.06)
        )
        static let track = dynamic(
            dark: UIColor(white: 1, alpha: 0.06),
            light: UIColor(white: 0, alpha: 0.10)
        )
        static let cardShadow = dynamic(
            dark: UIColor(white: 0, alpha: 0.25),
            light: UIColor(white: 0, alpha: 0.08)
        )
        static let columnShadow = dynamic(
            dark: UIColor(white: 0, alpha: 0.05),
            light: UIColor(white: 0, alpha: 0.03)
        )
        static let tinyShadow = dynamic(
            dark: UIColor(white: 0, alpha: 0.06),
            light: UIColor(white: 0, alpha: 0.04)
        )
        static let zoneDivider = dynamic(
            dark: UIColor(white: 1, alpha: 0.08),
            light: UIColor(white: 0, alpha: 0.12)
        )
        static let badgeBackground = dynamic(
            dark: UIColor(white: 1, alpha: 0.1),
            light: UIColor(white: 0, alpha: 0.08)
        )
        static let fabShadow = dynamic(
            dark: UIColor(white: 0, alpha: 0.35),
            light: UIColor(white: 0, alpha: 0.12)
        )
        static let checkmark = AppStyle.Colors.Status.done
        static let doneAccent = dynamic(
            dark: UIColor(red: 0.44, green: 0.84, blue: 0.62, alpha: 1),
            light: UIColor(red: 0.18, green: 0.58, blue: 0.38, alpha: 1)
        )
        static let warning = dynamic(
            dark: UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1),
            light: UIColor(red: 0.9, green: 0.3, blue: 0.0, alpha: 1)
        )
        static let blocked = dynamic(
            dark: UIColor(red: 0.98, green: 0.36, blue: 0.30, alpha: 1),
            light: UIColor(red: 0.78, green: 0.20, blue: 0.14, alpha: 1)
        )

        static let cardSheen = dynamic(
            dark: UIColor(white: 1, alpha: 0.04),
            light: UIColor(white: 0, alpha: 0.02)
        )

        static let fabGradient = LinearGradient(
            colors: [Status.todo, Status.inProgress],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Materials

    enum Materials {
        static let chrome = Material.ultraThin
        static let column = Material.regular
        static let alert = Material.regular
    }

    // MARK: - Typography

    enum Typography {
        static let heroTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let manifestoTitle = Font.system(.title, design: .rounded, weight: .bold)
        static let headerTitle = Font.system(.title3, design: .rounded, weight: .semibold)
        static let headerSubtitle = Font.subheadline.weight(.regular)
        static let compactHeaderTitle = Font.system(.title3, design: .rounded, weight: .bold)
        
        static let body = Font.body
        static let bodyLarge = Font.body.weight(.semibold)
        static let buttonLabel = Font.headline.weight(.semibold)
        static let secondaryAction = Font.subheadline.weight(.semibold)
        static let inlineHint = Font.caption.weight(.medium)

        static let sectionTitle = Font.caption.weight(.regular)
        static let sectionTracking: CGFloat = 1.8

        static let statusLabel = Font.subheadline.weight(.medium)
        static let statusLabelHighlighted = Font.subheadline.weight(.bold)
        static let statusCount = Font.subheadline.weight(.semibold)
        static let totalLabel = Font.subheadline.weight(.regular)
        
        static let pillLabel = Font.caption.weight(.bold)

        static let priorityNumber = Font.system(.title2, design: .rounded, weight: .bold)
        static let priorityLabel = Font.caption2.weight(.medium)
        static let priorityLabelBold = Font.caption.weight(.heavy)

        static let ringPercentage = Font.system(.title3, design: .rounded, weight: .bold)
        static let ringCaption = Font.caption2.weight(.medium)
        static let ringPercentageSmall = Font.caption2.weight(.bold)

        static let emptyIcon = Font.system(size: 42, weight: .light)
        static let emptyTitle = Font.title2.weight(.medium)
        static let emptySubtitle = Font.subheadline

        static let iconTiny = Font.system(size: 12, weight: .semibold)
        static let iconSmall = Font.system(size: 14, weight: .semibold)
        static let iconMedium = Font.system(size: 18, weight: .semibold)
        static let iconLarge = Font.system(size: 20, weight: .semibold)
        static let iconHero = Font.system(size: 22, weight: .semibold)
        static let iconAlert = Font.system(size: 34, weight: .semibold)
        static let checkbox = Font.system(size: AppStyle.Spacing.checkboxSize)
        static let zoneIcon = Font.caption2
        static let detailTitle = Font.title3.weight(.semibold)
        static let formFooter = Font.subheadline
        static let formField = Font.body

        static let fabIcon = Font.title2.weight(.semibold)
        static let columnHeader = Font.headline.weight(.semibold)
        static let zoneHeader = Font.caption.weight(.medium)
        static let zoneCount = Font.caption2.weight(.medium)
        static let cardTitle = Font.subheadline.weight(.semibold)
        static let cardDescription = Font.caption
        static let cardDate = Font.caption2
        static let tabLabel = Font.caption2.weight(.medium)
        static let guidanceFooter = Font.caption.weight(.regular)
        static let metricLarge = Font.system(.title, design: .rounded, weight: .bold)
        static let metricMedium = Font.system(.title3, design: .rounded, weight: .bold)
        static let metricSmall = Font.system(.subheadline, design: .rounded, weight: .bold)
        static let statusRowTitle = Font.system(.title3, design: .rounded, weight: .semibold)
        static let statusRowTitleHighlighted = Font.system(.title3, design: .rounded, weight: .bold)
        static let statusRowCount = Font.system(.title3, design: .rounded, weight: .bold)
        static let statLabel = Font.caption.weight(.medium)
    }

    // MARK: - Spacing

    enum Spacing {
        static let none: CGFloat = 0
        static let micro: CGFloat = 2
        static let tiny: CGFloat = 4
        static let tight: CGFloat = 6
        static let small: CGFloat = 8
        static let compact: CGFloat = 10
        static let medium: CGFloat = 12
        static let regular: CGFloat = 14
        static let normal: CGFloat = 16
        static let comfortable: CGFloat = 18
        static let large: CGFloat = 20
        static let heroPadding: CGFloat = 22
        static let extraLarge: CGFloat = 24

        static let interCardSpacing: CGFloat = 16
        static let sectionToCard: CGFloat = 16
        static let compactSectionSpacing: CGFloat = 24
        static let outerHorizontal: CGFloat = 24
        static let outerVertical: CGFloat = 24
        static let settingsBottomPadding: CGFloat = 120
        static let onboardingBottomPadding: CGFloat = 32
        
        static let pillHorizontalPadding: CGFloat = 10
        static let pillVerticalPadding: CGFloat = 4
        static let emphasizedPillHorizontalPadding: CGFloat = 12
        static let emphasizedPillVerticalPadding: CGFloat = 6
        
        static let dragHandleWidth: CGFloat = 24
        static let checkboxSize: CGFloat = 24

        static let cardPadding: CGFloat = 16
        static let cardContentPadding: CGFloat = 18
        static let compactCardPadding: CGFloat = 14
        static let headerPaddingVertical: CGFloat = 16
        static let headerPaddingHorizontal: CGFloat = 20
        static let statusCardVerticalPadding: CGFloat = 6
        static let priorityVerticalPadding: CGFloat = 20

        static let headerHStackGap: CGFloat = 24
        static let hStackGap: CGFloat = 14
        static let statusRowGap: CGFloat = 12
        static let priorityHStackGap: CGFloat = 12
        static let headerVStackGap: CGFloat = 6
        static let priorityCardVStackGap: CGFloat = 10
        static let sectionHStackGap: CGFloat = 5

        static let statusRowVertical: CGFloat = 13
        static let statusRowVerticalCompact: CGFloat = 12
        static let statusRowVerticalComfortable: CGFloat = 18
        static let statusRowVerticalHighlighted: CGFloat = 16
        static let statusRowSubtitleGap: CGFloat = 2
        static let totalRowVertical: CGFloat = 10

        static let statusLabelWidth: CGFloat = 88
        static let statusLabelWidthCompact: CGFloat = 80
        static let statusLabelWidthComfortable: CGFloat = 112
        static let countFrameWidth: CGFloat = 28
        static let countFrameWidthComfortable: CGFloat = 32
        static let statusCountWidthCompact: CGFloat = 24
        static let dividerLeading: CGFloat = 52
        static let dividerLeadingCompact: CGFloat = 44
        static let spacerWidth: CGFloat = 22
        static let stackedBarWidth: CGFloat = 100
        static let statusIconWidth: CGFloat = 20

        static let emptyStateSpacing: CGFloat = 20
        static let emptyStateVerticalPadding: CGFloat = 100

        static let boardHStackGap: CGFloat = 16
        static let fabPadding: CGFloat = 20
        static let columnPadding: CGFloat = 12
        static let columnContentSpacing: CGFloat = 12
        static let zoneVStackGap: CGFloat = 6
        static let zoneHStackGap: CGFloat = 4
        static let zoneContentMargin: CGFloat = 4
        static let cardVStackGap: CGFloat = 8
        static let iconFrameWidth: CGFloat = 16
        static let iconFrameWidthMedium: CGFloat = 24
        static let iconFrameWidthLarge: CGFloat = 28

        static let statusHighlightPaddingHorizontal: CGFloat = 6
        static let statusHighlightPaddingVertical: CGFloat = 4
        
        static let recentActivityCircleTopPadding: CGFloat = 6
        static let recentActivityRowVerticalPadding: CGFloat = 14

        static let badgeHorizontalPadding: CGFloat = 8
        static let badgeVerticalPadding: CGFloat = 3
        static let zonePaddingVertical: CGFloat = 6
        static let emptyBottomSpacer: CGFloat = 80
        static let tabBarIconGap: CGFloat = 3
        static let toastTopPadding: CGFloat = 10
    }

    // MARK: - Shapes

    enum Shapes {
        static let headerCornerRadius: CGFloat = 20
        static let cardCornerRadius: CGFloat = 16
        static let primaryControlCornerRadius: CGFloat = 18
        static let statusHighlightCornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 12
        static let tinyCornerRadius: CGFloat = 8
        static let pillCornerRadius: CGFloat = 8

        static let barHeight: CGFloat = 4
        static let statusDistributionBarHeight: CGFloat = 5
        static let previewAccentHeight: CGFloat = 6
        static let barHeightHighlighted: CGFloat = 7
        static let progressBarHeight: CGFloat = 10
        static let dotSize: CGFloat = 8
        static let activePageDotWidth: CGFloat = 28
        static let pageDotWidth: CGFloat = 8
        static let pageDotHeight: CGFloat = 8
        static let priorityDotSize: CGFloat = 5
        static let accentBarHeight: CGFloat = 3

        static let cardShadowRadius: CGFloat = 6
        static let cardShadowX: CGFloat = 2
        static let cardShadowY: CGFloat = 4
        static let borderWidth: CGFloat = 0.5
        static let emphasizedBorderWidth: CGFloat = 1
        static let warningBorderWidth: CGFloat = 2
        
        static let iconSizeMedium: CGFloat = 18
        static let iconSizeSmall: CGFloat = 14
        static let iconSizeTiny: CGFloat = 10
        static let buttonSizeMedium: CGFloat = 32
        static let iconBadgeSmall: CGFloat = 44
        static let iconBadgeMedium: CGFloat = 48
        static let iconBadgeLarge: CGFloat = 52
        static let alertIconSize: CGFloat = 58
        static let minimumTapTarget: CGFloat = 44
        
        static let dragScale: CGFloat = 1.05
        static let dragShadowRadius: CGFloat = 12

        static let ringSize: CGFloat = 56
        static let dashboardRingSize: CGFloat = 96
        static let dashboardRingTrackStroke: CGFloat = 9
        static let dashboardRingGlowStroke: CGFloat = 12
        static let compactRingSize: CGFloat = 44
        static let ringTrackStroke: CGFloat = 4
        static let compactRingTrackStroke: CGFloat = 3
        static let ringArcStroke: CGFloat = 3
        static let ringGlowStroke: CGFloat = 6
        static let compactRingGlowStroke: CGFloat = 5
        static let ringGlowBlur: CGFloat = 5
        static let compactRingGlowBlur: CGFloat = 4

        static let minBarWidth: CGFloat = 3
        static let cardAccentMinWidth: CGFloat = 28
        static let cardAccentHeight: CGFloat = 4
        static let progressMinWidth: CGFloat = 12
        static let progressBarMaxWidth: CGFloat = 420
        static let lanePreviewAccentWidth: CGFloat = 32
        static let formControlMinWidth: CGFloat = 132
        static let modalMaxWidth: CGFloat = 320
        static let voiceTranscriptMinHeight: CGFloat = 180
        static let statusIconSize: CGFloat = 14
        static let statusRowIconWidth: CGFloat = 24
        static let chevronWidth: CGFloat = 14
        static let dividerHeight: CGFloat = 1

        static let tinyShadowRadius: CGFloat = 4
        static let tinyShadowY: CGFloat = 2
        static let alertShadowRadius: CGFloat = 18
        static let alertShadowY: CGFloat = 10

        static let fabSize: CGFloat = 56
        static let fabShadowRadius: CGFloat = 8
        static let fabShadowX: CGFloat = 2
        static let fabShadowY: CGFloat = 5

        static let columnCornerRadius: CGFloat = 20
        static let columnShadowRadius: CGFloat = 8
        static let columnShadowY: CGFloat = 2
        static let zoneEmptyCornerRadius: CGFloat = 8
        static let zoneDropCornerRadius: CGFloat = 12
        static let zoneEmptyHeight: CGFloat = 40
        static let zoneEmptyOpacity: CGFloat = 0.3
        static let zoneDashLength: CGFloat = 4
        static let sideBarWidth: CGFloat = 4
        static let columnWidthRatio: CGFloat = 0.75
        static let columnMinWidth: CGFloat = 300
        static let columnMaxWidth: CGFloat = 380
        static let zoneMinHeight: CGFloat = 80
        static let tabBarCornerRadius: CGFloat = 22
        static let inspectorMinWidth: CGFloat = 320
        static let inspectorIdealWidth: CGFloat = 380
        static let alertTransitionScale: CGFloat = 0.98
        static let priorityFillBaseline: CGFloat = 0.18
        static let priorityFillRange: CGFloat = 0.52
    }

    // MARK: - Opacity

    enum Opacity {
        static let hidden: CGFloat = 0
        static let opaque: CGFloat = 1
        static let disabledControl: CGFloat = 0.55
        static let divider: CGFloat = 0.5
        static let subtleTrack: CGFloat = 0.6
        static let track: CGFloat = 0.65
        static let trackStrong: CGFloat = 0.7
        static let iconInactive: CGFloat = 0.3
        static let inactiveCard: CGFloat = 0.8
        static let scrollTransition: CGFloat = 0.6
        static let scrollScale: CGFloat = 0.95

        static let accentWashVeryFaint: CGFloat = 0.04
        static let accentWashFaint: CGFloat = 0.05
        static let accentWashSubtle: CGFloat = 0.08
        static let accentWash: CGFloat = 0.10
        static let accentWashStrong: CGFloat = 0.12
        static let accentWashEmphasized: CGFloat = 0.14
        static let accentWashSelected: CGFloat = 0.15
        static let accentFillMuted: CGFloat = 0.18
        static let accentForegroundMuted: CGFloat = 0.72
        static let accentForegroundStrong: CGFloat = 0.85
        static let accentForegroundEmphasized: CGFloat = 0.95
        static let accentBorder: CGFloat = 0.16
        static let accentBorderStrong: CGFloat = 0.18
        static let warningBorder: CGFloat = 0.30
        static let toast: CGFloat = 0.9
        static let glassTint: CGFloat = 0.04
        static let cardAccentTrailing: CGFloat = 0.45
        static let cardBorder: CGFloat = 0.08
        static let dragShadow: CGFloat = 0.18
        static let restingShadow: CGFloat = 0.08
    }

    // MARK: - Motion

    enum Motion {
        static let snappy = Animation.snappy
        static let standardSpring = Animation.spring()
        static let pageIndicator = Animation.spring(duration: 0.5, bounce: 0.2)
        static let progress = Animation.spring(duration: 0.9, bounce: 0.12)
        static let ringProgress = Animation.spring(duration: 1, bounce: 0.15)
        static let rowProgress = Animation.spring(response: 0.6, dampingFraction: 0.7)
        static let toastDismissDelay: TimeInterval = 2
        static let feedbackDismissDelay: TimeInterval = 1
    }

    // MARK: - Layers

    enum Layers {
        static let modal: Double = 1000
    }

}

// MARK: - View Modifier

extension View {
    func cardStyle(cornerRadius: CGFloat = AppStyle.Shapes.cardCornerRadius) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppStyle.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(AppStyle.Colors.cardSheen)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: AppStyle.Colors.cardShadow,
                radius: AppStyle.Shapes.cardShadowRadius,
                x: AppStyle.Shapes.cardShadowX,
                y: AppStyle.Shapes.cardShadowY
            )
    }

    func accentCardStyle(
        tint: Color,
        fillOpacity: CGFloat = AppStyle.Opacity.accentWashEmphasized,
        borderOpacity: CGFloat = AppStyle.Opacity.accentBorder,
        cornerRadius: CGFloat = AppStyle.Shapes.cardCornerRadius
    ) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [
                        tint.opacity(fillOpacity),
                        AppStyle.Colors.surface,
                        AppStyle.Colors.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(tint.opacity(borderOpacity), lineWidth: AppStyle.Shapes.emphasizedBorderWidth)
            )
    }

    func formFieldStyle() -> some View {
        self
            .font(AppStyle.Typography.formField)
            .padding(AppStyle.Spacing.normal)
            .background(AppStyle.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                    .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
            )
    }

    func sectionHeaderStyle() -> some View {
        self
            .font(AppStyle.Typography.sectionTitle)
            .foregroundStyle(AppStyle.Colors.secondaryText)
            .tracking(AppStyle.Typography.sectionTracking)
    }
}
