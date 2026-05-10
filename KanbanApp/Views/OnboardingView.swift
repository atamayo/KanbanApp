import SwiftUI

struct OnboardingView: View {
    @State private var page = 0

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                .animation(.snappy, value: page)

                footer
            }
            .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
            .padding(.top, AppStyle.Spacing.outerVertical)
            .padding(.bottom, 32)
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 18)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AppStyle.Colors.Status.todo : AppStyle.Colors.track)
                    .frame(width: index == page ? 28 : 8, height: 8)
                    .animation(.spring(duration: 0.5, bounce: 0.2), value: page)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Button {
                if page < 2 {
                    withAnimation(.snappy) {
                        page += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(page == 2 ? "Start Focusing" : "Continue")
                    .font(AppStyle.Typography.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppStyle.Colors.Status.todo, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Text(page == 2 ? "You can revisit the manifesto anytime from Settings." : "A focused system works better when you keep active work small.")
                .font(AppStyle.Typography.guidanceFooter)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 18)
    }
}
