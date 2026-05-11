import PhotosUI
import SwiftUI

struct QuickCapturePhotoImportButton: View {
    @Binding var selectedItem: PhotosPickerItem?
    let isBusy: Bool

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {
            HStack(spacing: AppStyle.Spacing.small) {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Import Photo")
            }
            .font(AppStyle.Typography.secondaryAction)
            .frame(minWidth: AppStyle.Shapes.formControlMinWidth)
        }
        .buttonStyle(.glass)
        .disabled(isBusy)
    }
}
