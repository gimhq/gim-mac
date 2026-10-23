import Foundation
import GIMClientKit
import Security

/// The secure store half of `PlatformHooks`: generic-password items of one service in the user's Keychain. No
/// access group and no `kSecAttrAccessible`: the file-based macOS Keychain supports neither without the
/// data-protection keychain.
final class KeychainSecureStorage: Sendable {
    private let service: String

    init(service: String = "im.g.mac") {
        self.service = service
    }

    /// `nil` when the key does not exist. Throws `GimError.Storage` when the Keychain can't be read, so gim-core
    /// never mistakes the secret for absent.
    func secureStoreGet(key: String) throws -> Data? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw GimError.Storage(reason: "Keychain read failed with status \(status)")
        }
    }

    /// Update or add. Throws `GimError.Storage` when the Keychain rejects the write.
    func secureStoreSet(key: String, value: Data) throws {
        let attributes: [String: Any] = [kSecValueData as String: value]
        var status = SecItemUpdate(baseQuery(key: key) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let query = baseQuery(key: key).merging(attributes) { _, new in new }
            status = SecItemAdd(query as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            throw GimError.Storage(reason: "Keychain write failed with status \(status)")
        }
    }

    /// A missing key is not an error.
    func secureStoreDelete(key: String) {
        SecItemDelete(baseQuery(key: key) as CFDictionary)
    }

    /// Deletes every item of this service. Throws `GimError.Storage` when the Keychain rejects the delete.
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GimError.Storage(reason: "Keychain delete failed with status \(status)")
        }
    }

    private func baseQuery(key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
