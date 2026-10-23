import Foundation
import GIMClientKit

/// Platform hooks that can erase everything they stored, as a backstop after signing out.
protocol PlatformWiping {
    func wipe() throws
}

/// The app's `PlatformHooks`: Keychain secrets, the Application Support data directory and network reachability.
final class MacPlatformHooks: PlatformHooks, PlatformWiping {
    let keychain: KeychainSecureStorage
    let reachability: ReachabilityMonitor
    private let dataDirectory: String

    init(
        dataDirectory: String,
        keychain: KeychainSecureStorage = KeychainSecureStorage(),
        reachability: ReachabilityMonitor = ReachabilityMonitor()
    ) {
        self.dataDirectory = dataDirectory
        self.keychain = keychain
        self.reachability = reachability
    }

    /// Hooks on `AppDirectories.dataDirectory`.
    static func standard() throws -> MacPlatformHooks {
        MacPlatformHooks(dataDirectory: try AppDirectories.dataDirectory.path)
    }

    func secureStoreGet(key: String) throws -> Data? {
        try keychain.secureStoreGet(key: key)
    }

    func secureStoreSet(key: String, value: Data) throws {
        try keychain.secureStoreSet(key: key, value: value)
    }

    func secureStoreDelete(key: String) {
        keychain.secureStoreDelete(key: key)
    }

    func dataDir() -> String {
        dataDirectory
    }

    func isNetworkReachable() -> Bool {
        reachability.isReachable
    }

    /// Deletes all Keychain items of the app's service and the contents of the data directory (keeping the
    /// directory itself).
    func wipe() throws {
        try keychain.deleteAll()
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: dataDirectory) else { return }
        for name in try fileManager.contentsOfDirectory(atPath: dataDirectory) {
            try fileManager.removeItem(atPath: (dataDirectory as NSString).appendingPathComponent(name))
        }
    }
}
