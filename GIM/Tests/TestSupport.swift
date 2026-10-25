import Foundation
import GIMClientKit
import Synchronization

@testable import GIM

/// In-memory secure store, a unique temporary data directory and a reachable network.
final class TestPlatformHooks: PlatformHooks {
    private let store = Mutex<[String: Data]>([:])
    private let dataDirectory: URL

    init() {
        dataDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-mac-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }

    func secureStoreGet(key: String) throws -> Data? {
        store.withLock { $0[key] }
    }

    func secureStoreSet(key: String, value: Data) throws {
        store.withLock { $0[key] = value }
    }

    func secureStoreDelete(key: String) {
        store.withLock { $0[key] = nil }
    }

    func dataDir() -> String {
        dataDirectory.path
    }

    func isNetworkReachable() -> Bool {
        true
    }
}

/// A fresh, empty defaults suite.
func makeTestDefaults() -> UserDefaults {
    let suite = "im.g.mac.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

/// A model on the demo client with an immediate scheduler, test hooks and `defaults`.
@MainActor
func makeTestModel(
    defaults: UserDefaults = makeTestDefaults(), bundledServerUrl: String? = "http://localhost:8080"
) -> AppModel {
    AppModel(
        factory: FakeGimClientFactory(scheduler: ImmediateFakeScheduler()),
        hooks: { TestPlatformHooks() },
        defaults: defaults,
        bundledServerUrl: bundledServerUrl)
}

/// `FakeRecoveryKitFunctions` with a fixed parse result and ending check, so a test can tell that a view model calls
/// the functions it was given rather than its own copy.
struct StubRecoveryKitFunctions: RecoveryKitFunctions {
    var parsed: ParsedRecoveryKit
    /// The only text `matchesRecoveryKeyEnding` accepts.
    var ending: String

    func formatRecoveryKit(userId: String, recoveryCode: String, labels: RecoveryKitLabels) -> String {
        FakeRecoveryKitFunctions().formatRecoveryKit(userId: userId, recoveryCode: recoveryCode, labels: labels)
    }

    func parseRecoveryKit(text: String) -> ParsedRecoveryKit {
        parsed
    }

    func recoveryKeyEnding(recoveryCode: String) -> String {
        ending
    }

    func matchesRecoveryKeyEnding(recoveryCode: String, typed: String) -> Bool {
        typed == ending
    }
}
