import Foundation
import UIKit
import Vision

enum ImageTextExtractionError: LocalizedError {
    case unsupportedImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .unsupportedImage:
            return String(localized: "The selected image could not be read.")
        case .noTextFound:
            return String(localized: "No readable text was found in that image.")
        }
    }
}

enum ImageTextExtractionService {
    static func extractText(from imageData: Data) async throws -> String {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw ImageTextExtractionError.unsupportedImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let extractedText = observations
                    .compactMap { $0.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !extractedText.isEmpty else {
                    continuation.resume(throwing: ImageTextExtractionError.noTextFound)
                    return
                }

                continuation.resume(returning: extractedText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage)

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
