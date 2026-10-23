import Foundation
import GIMClientKit

/// Selects the `GimClientFactory` the app runs with.
enum ClientFactories {
    /// Debug builds use the demo client instead of GIMCore when launched with `-GIMUseFakeCore YES`.
    static let useFakeCoreKey = "GIMUseFakeCore"

    /// GIMCore (`RealGimClientFactory`); in Debug builds the `useFakeCoreKey` launch argument selects the demo client
    /// (`CoreGimClientFactory`, which starts without a session so onboarding appears). Release builds always use
    /// GIMCore.
    static func `default`(defaults: UserDefaults = .standard) -> any GimClientFactory {
        #if DEBUG
            if defaults.bool(forKey: useFakeCoreKey) { return CoreGimClientFactory() }
        #endif
        return RealGimClientFactory()
    }
}

/// Demo clients with an injectable scheduler, for tests.
struct FakeGimClientFactory: GimClientFactory {
    var scheduler: any FakeScheduler = RealDelayFakeScheduler()

    func make(config: ClientConfig, hooks: any PlatformHooks) async throws -> any GimClientAPI {
        FakeGimClient.demo(
            scheduler: scheduler, dataDirectory: hooks.dataDir(), registered: false,
            networkReachable: hooks.isNetworkReachable(), homeHubUrl: config.serverUrl, mode: config.mode)
    }
}
