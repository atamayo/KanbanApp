import SwiftUI

enum AppStyle {

    // MARK: - Dynamic Color Helper

    private static func dynamic(dark: UIColor, light: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    // MARK: - Colors

    enum Colors {
        static let background = dynamic(
            dark: UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1),
            light: UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        )

        static let surface = Color(.secondarySystemBackground)

        static let surfaceBorder = dynamic(
            dark: UIColor(white: 1, alpha: 0.06),
            light: UIColor(white: 0, alpha: 0.08)
        )

        static let subtleText = Color.secondary

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
                dark: UIColor(red: 0.90, green: 0.60, blue: 0.30, alpha: 1),
                light: UIColor(red: 0.80, green: 0.45, blue: 0.18, alpha: 1)
            )
            static let low = dynamic(
                dark: UIColor(red: 0.35, green: 0.68, blue: 0.72, alpha: 1),
                light: UIColor(red: 0.15, green: 0.55, blue: 0.60, alpha: 1)
            )
        }

        enum Zone {
            static let high = Color.red
            static let medium = Color.secondary
            static let low = Color.secondary.opacity(0.5)
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
        static let checkmark = Color.green
        static let warning = dynamic(
            dark: UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1),
            light: UIColor(red: 0.9, green: 0.3, blue: 0.0, alpha: 1)
        )

        static let cardSheen = dynamic(
            dark: UIColor(white: 1, alpha: 0.04),
            light: UIColor(white: 0, alpha: 0.02)
        )

        static let fabGradient = LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Typography

    enum Typography {
        static let headerTitle = Font.system(size: 20, weight: .semibold)
        static let headerSubtitle = Font.subheadline.weight(.regular)
        static let compactHeaderTitle = Font.title3.weight(.bold)
        
        static let bodyLarge = Font.system(size: 17, weight: .semibold)

        static let sectionTitle = Font.caption.weight(.regular)
        static let sectionTracking: CGFloat = 1.8

        static let statusLabel = Font.subheadline.weight(.medium)
        static let statusLabelHighlighted = Font.subheadline.weight(.bold)
        static let statusCount = Font.subheadline.weight(.semibold)
        static let totalLabel = Font.subheadline.weight(.regular)
        
        static let pillLabel = Font.caption.weight(.bold)

        static let priorityNumber = Font.system(size: 26, weight: .bold)
        static let priorityLabel = Font.caption2.weight(.medium)
        static let priorityLabelBold = Font.caption.weight(.heavy)

        static let ringPercentage = Font.system(size: 13, weight: .bold)
        static let ringPercentageSmall = Font.system(size: 10, weight: .bold)

        static let emptyIcon = Font.system(size: 42, weight: .light)
        static let emptyTitle = Font.title2.weight(.medium)
        static let emptySubtitle = Font.subheadline

        static let zoneIcon = Font.caption2
        static let detailTitle = Font.title3.weight(.semibold)
        static let formFooter = Font.subheadline

        static let fabIcon = Font.title2.weight(.semibold)
        static let columnHeader = Font.headline.weight(.semibold)
        static let zoneHeader = Font.caption.weight(.medium)
        static let zoneCount = Font.caption2.weight(.medium)
        static let cardTitle = Font.subheadline.weight(.semibold)
        static let cardDescription = Font.caption
        static let cardDate = Font.caption2
        static let tabLabel = Font.caption2.weight(.medium)
        static let guidanceFooter = Font.caption.weight(.regular)
    }

    // MARK: - Spacing

    enum Spacing {
        static let none: CGFloat = 0
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let normal: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24

        static let interCardSpacing: CGFloat = 16
        static let sectionToCard: CGFloat = 16
        static let compactSectionSpacing: CGFloat = 24
        static let outerHorizontal: CGFloat = 24
        static let outerVertical: CGFloat = 24
        
        static let pillHorizontalPadding: CGFloat = 10
        static let pillVerticalPadding: CGFloat = 4
        
        static let dragHandleWidth: CGFloat = 24
        static let checkboxSize: CGFloat = 24

        static let cardPadding: CGFloat = 16
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
        static let statusRowVerticalHighlighted: CGFloat = 16
        static let totalRowVertical: CGFloat = 10

        static let statusLabelWidth: CGFloat = 88
        static let statusLabelWidthCompact: CGFloat = 80
        static let countFrameWidth: CGFloat = 28
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

        static let statusHighlightPaddingHorizontal: CGFloat = 6
        static let statusHighlightPaddingVertical: CGFloat = 4
        
        static let recentActivityCircleTopPadding: CGFloat = 6
        static let recentActivityRowVerticalPadding: CGFloat = 14

        static let badgeHorizontalPadding: CGFloat = 8
        static let badgeVerticalPadding: CGFloat = 3
        static let zonePaddingVertical: CGFloat = 6
        static let emptyBottomSpacer: CGFloat = 80
        static let tabBarIconGap: CGFloat = 3
    }

    // MARK: - Shapes

    enum Shapes {
        static let headerCornerRadius: CGFloat = 20
        static let cardCornerRadius: CGFloat = 16
        static let statusHighlightCornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 12
        static let tinyCornerRadius: CGFloat = 8
        static let pillCornerRadius: CGFloat = 8

        static let barHeight: CGFloat = 4
        static let barHeightHighlighted: CGFloat = 7
        static let dotSize: CGFloat = 8
        static let priorityDotSize: CGFloat = 5
        static let accentBarHeight: CGFloat = 3

        static let cardShadowRadius: CGFloat = 6
        static let cardShadowX: CGFloat = 2
        static let cardShadowY: CGFloat = 4
        static let borderWidth: CGFloat = 0.5
        
        static let iconSizeMedium: CGFloat = 18
        static let iconSizeSmall: CGFloat = 14
        static let iconSizeTiny: CGFloat = 10
        static let buttonSizeMedium: CGFloat = 32
        
        static let dragScale: CGFloat = 1.05
        static let dragShadowRadius: CGFloat = 12

        static let ringSize: CGFloat = 56
        static let compactRingSize: CGFloat = 44
        static let ringTrackStroke: CGFloat = 4
        static let compactRingTrackStroke: CGFloat = 3
        static let ringArcStroke: CGFloat = 3
        static let ringGlowStroke: CGFloat = 6
        static let compactRingGlowStroke: CGFloat = 5
        static let ringGlowBlur: CGFloat = 5
        static let compactRingGlowBlur: CGFloat = 4

        static let minBarWidth: CGFloat = 3
        static let statusIconSize: CGFloat = 14
        static let dividerHeight: CGFloat = 1

        static let tinyShadowRadius: CGFloat = 4
        static let tinyShadowY: CGFloat = 2

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
        static let zoneMinHeight: CGFloat = 80
        static let tabBarCornerRadius: CGFloat = 22
        static let inspectorMinWidth: CGFloat = 320
        static let inspectorIdealWidth: CGFloat = 380
    }

}

// MARK: - View Modifier

extension View {
    func cardStyle(cornerRadius: CGFloat) -> some View {
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
}
