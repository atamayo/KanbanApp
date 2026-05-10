import SwiftUI

struct CustomAlertView: View {
    @Binding var isPresented: Bool
    let iconName: String
    let title: String
    let message: String
    var buttonTitle = "OK"

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                VStack(spacing: AppStyle.Spacing.normal) {
                    Image(systemName: iconName)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.Status.inProgress)
                        .frame(width: 58, height: 58)
                        .background(AppStyle.Colors.Status.inProgress.opacity(0.12), in: .circle)

                    VStack(spacing: AppStyle.Spacing.small) {
                        Text(title)
                            .font(AppStyle.Typography.headerTitle)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text(message)
                            .font(AppStyle.Typography.formFooter)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        withAnimation(.snappy) {
                            isPresented = false
                        }
                    } label: {
                        Text(buttonTitle)
                            .font(AppStyle.Typography.bodyLarge)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppStyle.Spacing.medium)
                            .background(AppStyle.Colors.Status.todo, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(buttonTitle)
                }
                .padding(AppStyle.Spacing.extraLarge)
                .frame(maxWidth: 320)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                        .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                }
                .shadow(color: AppStyle.Colors.cardShadow, radius: 18, x: 0, y: 10)
                .padding(.horizontal, AppStyle.Spacing.extraLarge)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .zIndex(1000)
        }
    }
}

extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        iconName: String,
        title: String,
        message: String,
        buttonTitle: String = "OK"
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            CustomAlertView(
                isPresented: isPresented,
                iconName: iconName,
                title: title,
                message: message,
                buttonTitle: buttonTitle
            )
            .presentationBackground(.clear)
            .interactiveDismissDisabled()
        }
    }
}
