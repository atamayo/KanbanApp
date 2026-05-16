import SwiftUI

struct CustomAlertView: View {
    @Binding var isPresented: Bool
    let iconName: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var buttonTitle: LocalizedStringKey = "OK"

    var body: some View {
        if isPresented {
            ZStack {
                AppStyle.Colors.scrim
                    .ignoresSafeArea()

                VStack(spacing: AppStyle.Spacing.normal) {
                    Image(systemName: iconName)
                        .font(AppStyle.Typography.iconAlert)
                        .foregroundStyle(AppStyle.Colors.Status.inProgress)
                        .frame(width: AppStyle.Shapes.alertIconSize, height: AppStyle.Shapes.alertIconSize)
                        .background(AppStyle.Colors.Status.inProgress.opacity(AppStyle.Opacity.accentWashStrong), in: .circle)

                    VStack(spacing: AppStyle.Spacing.small) {
                        Text(title)
                            .font(AppStyle.Typography.headerTitle)
                            .foregroundStyle(AppStyle.Colors.primaryText)
                            .multilineTextAlignment(.center)

                        Text(message)
                            .font(AppStyle.Typography.formFooter)
                            .foregroundStyle(AppStyle.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        withAnimation(AppStyle.Motion.snappy) {
                            isPresented = false
                        }
                    } label: {
                        Text(buttonTitle)
                            .font(AppStyle.Typography.bodyLarge)
                            .foregroundStyle(AppStyle.Colors.inverseText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppStyle.Spacing.medium)
                            .background(AppStyle.Colors.Status.todo, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(buttonTitle))
                }
                .padding(AppStyle.Spacing.extraLarge)
                .frame(maxWidth: AppStyle.Shapes.modalMaxWidth)
                .background(AppStyle.Materials.alert, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppStyle.Shapes.cardCornerRadius, style: .continuous)
                        .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                }
                .shadow(
                    color: AppStyle.Colors.cardShadow,
                    radius: AppStyle.Shapes.alertShadowRadius,
                    x: AppStyle.Spacing.none,
                    y: AppStyle.Shapes.alertShadowY
                )
                .padding(.horizontal, AppStyle.Spacing.extraLarge)
            }
            .transition(.opacity.combined(with: .scale(scale: AppStyle.Shapes.alertTransitionScale)))
            .zIndex(AppStyle.Layers.modal)
        }
    }
}

extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        iconName: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        buttonTitle: LocalizedStringKey = "OK"
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
