import GIMClientKit

/// Selects the `GimClientFactory` the app runs with.
///
/// TODO: wire `RealGimClientFactory` for GIMCore (contract C5) behind the same `GimClientFactory` protocol, shaped
/// like gim-ios `GIMPlatform/Bridge`. Until then the fake client is the only mode (demo mode).
enum ClientFactories {
    /// `CoreGimClientFactory` validates the server URL and currently returns the demo client without a session, so
    /// onboarding appears on first launch.
    static func `default`() -> any GimClientFactory {
        CoreGimClientFactory()
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
