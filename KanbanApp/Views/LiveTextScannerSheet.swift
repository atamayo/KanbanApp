import SwiftUI
import VisionKit

enum LiveTextScannerError: LocalizedError {
    case unsupported
    case unavailable
    case noTextFound
    case cameraAccessDenied

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Live text scanning is not supported on this device."
        case .unavailable:
            return "The camera scanner is unavailable right now."
        case .noTextFound:
            return "No readable text was found in the camera view."
        case .cameraAccessDenied:
            return "Camera access is required to scan text. Enable it in Settings."
        }
    }
}

struct LiveTextScannerSheet: View {
    let onRecognizedText: (String) -> Void
    let onError: (LiveTextScannerError) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var recognizedText = ""
    @State private var scannerError: LiveTextScannerError?

    private var canUseCapturedText: Bool {
        !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if let scannerError {
                    scannerUnavailableState(scannerError)
                } else {
                    LiveTextScannerView(
                        recognizedText: $recognizedText,
                        scannerError: $scannerError
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle("Scan Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Use Text") {
                        let cleanedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                        onRecognizedText(cleanedText)
                    }
                    .disabled(!canUseCapturedText)
                }
            }
        }
        .onChange(of: scannerError) { _, newValue in
            guard let newValue else { return }
            onError(newValue)
        }
    }

    private func scannerUnavailableState(_ error: LiveTextScannerError) -> some View {
        VStack(spacing: AppStyle.Spacing.emptyStateSpacing) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(AppStyle.Typography.emptyIcon)
                .foregroundStyle(AppStyle.Colors.secondaryText)
            Text("Scanner unavailable")
                .font(AppStyle.Typography.emptyTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)
            Text(error.localizedDescription)
                .font(AppStyle.Typography.emptySubtitle)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .multilineTextAlignment(.center)
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.glassProminent)
            Spacer()
        }
        .padding(AppStyle.Spacing.extraLarge)
        .background(AppStyle.Colors.background)
    }
}

private struct LiveTextScannerView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var scannerError: LiveTextScannerError?

    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedText: $recognizedText, scannerError: $scannerError)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        guard scannerError == nil else { return }

        guard DataScannerViewController.isSupported else {
            scannerError = .unsupported
            return
        }

        guard DataScannerViewController.isAvailable else {
            scannerError = .unavailable
            return
        }

        guard !uiViewController.isScanning else { return }

        do {
            try uiViewController.startScanning()
        } catch {
            scannerError = .unavailable
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding private var recognizedText: String
        @Binding private var scannerError: LiveTextScannerError?
        private var textByItemID: [RecognizedItem.ID: String] = [:]

        init(recognizedText: Binding<String>, scannerError: Binding<LiveTextScannerError?>) {
            _recognizedText = recognizedText
            _scannerError = scannerError
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            merge(addedItems)
            refreshRecognizedText(from: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            merge(updatedItems)
            refreshRecognizedText(from: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            removedItems.forEach { textByItemID.removeValue(forKey: $0.id) }
            refreshRecognizedText(from: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            scannerError = .unavailable
        }

        private func merge(_ items: [RecognizedItem]) {
            for item in items {
                guard case .text(let text) = item else { continue }
                let cleanedText = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanedText.isEmpty {
                    textByItemID.removeValue(forKey: item.id)
                } else {
                    textByItemID[item.id] = cleanedText
                }
            }
        }

        private func refreshRecognizedText(from items: [RecognizedItem]) {
            let orderedLines = items.compactMap { item -> String? in
                guard case .text = item else { return nil }
                return textByItemID[item.id]
            }

            recognizedText = orderedLines
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
