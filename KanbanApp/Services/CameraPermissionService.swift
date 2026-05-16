import AVFoundation

enum CameraPermissionResult {
    case granted
    case denied
    case unavailable
}

enum CameraPermissionService {
    static func requestCameraAccess() async -> CameraPermissionResult {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .granted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .granted : .denied
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .unavailable
        }
    }
}
