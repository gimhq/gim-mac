import GIMFeatures
import LocalAuthentication

/// Asks the Mac's owner to authenticate with Touch ID or the login password
/// (`LAPolicy.deviceOwnerAuthentication`).
struct MacDeviceAuthenticator: DeviceAuthenticator {
    func authenticate(reason: String) async -> DeviceAuthResult {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return Self.result(for: error)
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                ? .success : .failed
        } catch {
            return Self.result(for: error)
        }
    }

    /// Maps a LocalAuthentication error to the result: cancelling is not an error, a Mac without a password or
    /// Touch ID cannot authenticate, anything else failed.
    static func result(for error: (any Error)?) -> DeviceAuthResult {
        guard let error = error as? LAError else { return .failed }
        switch error.code {
        case .userCancel, .appCancel, .systemCancel, .userFallback:
            return .cancelled
        case .passcodeNotSet, .biometryNotAvailable, .biometryNotEnrolled, .notInteractive:
            return .unavailable
        default:
            return .failed
        }
    }
}
