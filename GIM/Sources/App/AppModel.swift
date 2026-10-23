import Foundation
import GIMClientKit
import GIMFeatures
import Observation

/// Owns the client and decides whether the app shows onboarding or the signed-in UI.
///
/// The client is created once at launch for `resolvedServerUrl()`; its session routes to `.ready` or
/// `.onboarding`. Signing out drops the client and starts over.
@MainActor
@Observable
final class AppModel {
    enum Phase {
        case launching
        case onboarding
        case ready
    }

    /// Launch argument (`-GIMDefaultServerURL <url>`) and Info.plist key (`GIM_DEFAULT_SERVER_URL` build setting).
    nonisolated static let defaultServerUrlKey = "GIMDefaultServerURL"
    /// Last used server.
    nonisolated static let serverUrlKey = "gim.serverUrl"
    nonisolated static let builtInServerUrl = "https://hub.g.im"

    private(set) var phase: Phase = .launching
    private(set) var session: Session?
    /// Set when the platform hooks, the client or the session could not be read while launching.
    private(set) var launchError: String?
    /// Server of the signed-in client.
    private(set) var serverUrl: String?
    var showsMenuBarExtra = false
    private(set) var client: (any GimClientAPI)?
    /// Chat list and selection of the main window; set while `.ready`.
    private(set) var sidebar: SidebarModel?

    /// The main window's selected chat; `nil` while signed out.
    var selectedChatId: String? {
        get { sidebar?.selectedChatId }
        set { sidebar?.selectedChatId = newValue }
    }

    private let factory: any GimClientFactory
    private let makeHooks: @MainActor () throws -> any PlatformHooks
    private let defaults: UserDefaults
    private let bundledServerUrl: String?
    @ObservationIgnored private var hooks: (any PlatformHooks)?
    @ObservationIgnored private var config: ClientConfig?

    /// Makes clients; onboarding uses it for a server other than the launch one.
    var clientFactory: any GimClientFactory { factory }

    /// - Parameters:
    ///   - factory: makes the client; see `ClientFactories`.
    ///   - hooks: builds the platform hooks handed to the factory (once per process).
    ///   - defaults: remembers the last server URL; its argument domain may hold `defaultServerUrlKey`.
    ///   - bundledServerUrl: the Info.plist `defaultServerUrlKey` value.
    init(
        factory: any GimClientFactory = ClientFactories.default(),
        hooks: @escaping @MainActor () throws -> any PlatformHooks = { try MacPlatformHooks.standard() },
        defaults: UserDefaults = .standard,
        bundledServerUrl: String? = Bundle.main.object(forInfoDictionaryKey: AppModel.defaultServerUrlKey) as? String
    ) {
        self.factory = factory
        self.makeHooks = hooks
        self.defaults = defaults
        self.bundledServerUrl = bundledServerUrl
    }

    /// Last used server, else the launch argument, else the bundled default, else `builtInServerUrl`. Not
    /// validated here; the factory validates.
    func resolvedServerUrl() -> String {
        let candidates = [
            defaults.string(forKey: Self.serverUrlKey),
            defaults.string(forKey: Self.defaultServerUrlKey),
            bundledServerUrl,
        ]
        return candidates.compactMap { $0 }.first { !$0.isEmpty } ?? Self.builtInServerUrl
    }

    /// Creates the client for `resolvedServerUrl()` and routes by its session. Safe to call again after a launch
    /// error.
    func start() async {
        guard phase == .launching else { return }
        launchError = nil
        do {
            let hooks = try platformHooks()
            let config = ClientConfig(serverUrl: resolvedServerUrl())
            let client = try await factory.make(config: config, hooks: hooks)
            self.client = client
            self.config = config
            if let session = try await client.session() {
                becomeReady(session: session)
            } else {
                phase = .onboarding
            }
        } catch {
            launchError = ErrorPresenter.message(for: error)
        }
    }

    /// Creates an identity on the current client and signs in.
    func createDemoIdentity(displayName: String) async throws {
        guard let client else { throw GimError.NotRegistered }
        _ = try await client.createIdentity(displayName: displayName)
        guard let session = try await client.session() else { throw GimError.NotRegistered }
        becomeReady(session: session)
    }

    /// Signs out, wipes the platform keystore and data directory (`PlatformWiping`), drops the client and starts
    /// over. Returns the error text when signing out or wiping fails; a failed wipe still starts over.
    func signOut() async -> String? {
        guard let client else { return nil }
        do {
            try await client.signOut()
        } catch {
            return ErrorPresenter.message(for: error)
        }
        var wipeError: String?
        do {
            try (hooks as? any PlatformWiping)?.wipe()
        } catch {
            wipeError = ErrorPresenter.message(for: error)
        }
        (hooks as? MacPlatformHooks)?.reachability.attach(nil)
        sidebar?.stop()
        sidebar = nil
        self.client = nil
        config = nil
        session = nil
        serverUrl = nil
        phase = .launching
        await start()
        return wipeError
    }

    /// Signs in with the client onboarding registered, linked or restored.
    func signIn(_ registration: Registration) {
        client = registration.client
        config = registration.config
        becomeReady(session: registration.session)
    }

    /// The platform hooks of this process, built on first use.
    func platformHooks() throws -> any PlatformHooks {
        if let hooks { return hooks }
        let hooks = try makeHooks()
        self.hooks = hooks
        return hooks
    }

    private func becomeReady(session: Session) {
        guard let client, let config else { return }
        self.session = session
        serverUrl = config.serverUrl
        defaults.set(config.serverUrl, forKey: Self.serverUrlKey)
        (hooks as? MacPlatformHooks)?.reachability.attach(client)
        let sidebar = SidebarModel(client: client)
        sidebar.start()
        self.sidebar = sidebar
        phase = .ready
        Task { try? await client.startSync() }
    }
}
