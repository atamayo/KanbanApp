import SwiftUI

struct OnboardingView: View {
    @State private var page = 0

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppStyle.Spacing.none) {
                header

                TabView(selection: $page) {
                    OnboardingWelcomePageView()
                        .tag(0)

                    OnboardingFocusPageView()
                        .tag(1)

                    OnboardingManifestoPageView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppStyle.Motion.snappy, value: page)

                footer
            }
            .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
            .padding(.top, AppStyle.Spacing.outerVertical)
            .padding(.bottom, AppStyle.Spacing.onboardingBottomPadding)
            .background(AppStyle.Colors.background)
        }
    }

    private var header: some View {
        HStack {
            progressDots

            Spacer()

            if page < 2 {
                Button("Skip") {
                    onComplete()
                }
                .font(AppStyle.Typography.secondaryAction)
                .foregroundStyle(AppStyle.Colors.secondaryText)
            }
        }
        .padding(.bottom, AppStyle.Spacing.comfortable)
    }

    private var progressDots: some View {
        HStack(spacing: AppStyle.Spacing.small) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AppStyle.Colors.Status.todo : AppStyle.Colors.track)
                    .frame(width: index == page ? AppStyle.Shapes.activePageDotWidth : AppStyle.Shapes.pageDotWidth, height: AppStyle.Shapes.pageDotHeight)
                    .animation(AppStyle.Motion.pageIndicator, value: page)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: AppStyle.Spacing.regular) {
            Button {
                if page < 2 {
                    withAnimation(AppStyle.Motion.snappy) {
                        page += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(page == 2 ? "Start Focusing" : "Continue")
                    .font(AppStyle.Typography.bodyLarge)
                    .foregroundStyle(AppStyle.Colors.inverseText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppStyle.Spacing.normal)
                    .background(AppStyle.Colors.Status.todo, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.primaryControlCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            Text(page == 2 ? "You can revisit the manifesto anytime from Settings." : "A focused system works better when you keep active work small.")
                .font(AppStyle.Typography.guidanceFooter)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppStyle.Spacing.comfortable)
    }
}
