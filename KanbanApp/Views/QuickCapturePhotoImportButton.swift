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
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Import Photo")
            }
            .font(.subheadline.weight(.semibold))
            .frame(minWidth: 132)
        }
        .buttonStyle(.glass)
        .disabled(isBusy)
    }
}
