import Foundation

/// The app's version and build number from its Info.plist.
struct AppVersionInfo: Equatable {
    let version: String
    let build: String

    /// Reads `CFBundleShortVersionString` and `CFBundleVersion`; "?" for a missing value.
    static func from(_ info: [String: Any]) -> AppVersionInfo {
        AppVersionInfo(
            version: info["CFBundleShortVersionString"] as? String ?? "?",
            build: info["CFBundleVersion"] as? String ?? "?")
    }

    static var current: AppVersionInfo {
        from(Bundle.main.infoDictionary ?? [:])
    }
}
