import Foundation
import GIMClientKit
import GIMFeatures
import Synchronization
import XCTest

@testable import GIM

/// `FakeGimClientFactory` that records the configs it was asked for; the demo client never contacts a network.
final class RecordingGimClientFactory: GimClientFactory {
    private let base = FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
    private let recorded = Mutex<[ClientConfig]>([])

    var configs: [ClientConfig] { recorded.withLock { $0 } }

    func make(config: ClientConfig, hooks: any PlatformHooks) async throws -> any GimClientAPI {
        recorded.withLock { $0.append(config) }
        return try await base.make(config: config, hooks: hooks)
    }
}

@MainActor
final class KeepServerWiringTests: XCTestCase {
    /// The test scheme passes `-GIMDefaultKeepServerURL off`; it is lifted while a test runs so the bundled value and
    /// the built-in default can be observed, and restored afterwards.
    private var argumentDomain: [String: Any] = [:]

    override func setUp() async throws {
        argumentDomain = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        var lifted = argumentDomain
        lifted[KeepServer.defaultUrlKey] = nil
        UserDefaults.standard.setVolatileDomain(lifted, forName: UserDefaults.argumentDomain)
    }

    override func tearDown() async throws {
        UserDefaults.standard.setVolatileDomain(argumentDomain, forName: UserDefaults.argumentDomain)
    }

    func testDefaultIsBuiltInWithoutOverrides() {
        let defaults = makeTestDefaults()
        XCTAssertNil(defaults.string(forKey: KeepServer.defaultUrlKey))
        let model = makeTestModel(defaults: defaults, bundledKeepServerUrl: nil)
        XCTAssertEqual(model.defaultKeepServerUrl, KeepServer.builtInUrl)
    }

    func testBundledUrlReplacesBuiltIn() {
        let model = makeTestModel(bundledKeepServerUrl: "https://keep.test")
        XCTAssertEqual(model.defaultKeepServerUrl, "https://keep.test")
    }

    func testBundledOffMeansNone() {
        let model = makeTestModel(bundledKeepServerUrl: "off")
        XCTAssertNil(model.defaultKeepServerUrl)
    }

    func testStoredOffWinsOverBundled() async {
        let defaults = makeTestDefaults()
        KeepServer.store(.off, in: defaults)
        let model = makeTestModel(defaults: defaults, bundledKeepServerUrl: "https://keep.test")
        await model.start()
        XCTAssertNil(model.keepServerUrl)
    }

    func testStoredCustomWins() async {
        let defaults = makeTestDefaults()
        KeepServer.store(.custom("https://custom.keep.test"), in: defaults)
        let model = makeTestModel(defaults: defaults, bundledKeepServerUrl: "https://keep.test")
        await model.start()
        XCTAssertEqual(model.keepServerUrl, "https://custom.keep.test")
    }

    func testResetReturnsToDefault() async {
        let defaults = makeTestDefaults()
        KeepServer.store(.custom("https://custom.keep.test"), in: defaults)
        KeepServer.store(.automatic, in: defaults)
        let model = makeTestModel(defaults: defaults, bundledKeepServerUrl: "https://keep.test")
        await model.start()
        XCTAssertEqual(model.keepServerUrl, "https://keep.test")
        XCTAssertEqual(model.keepServerUrl, model.defaultKeepServerUrl)
    }

    func testStartPassesKeepServerToClient() async {
        let defaults = makeTestDefaults()
        KeepServer.store(.custom("https://custom.keep.test"), in: defaults)
        let factory = RecordingGimClientFactory()
        let model = makeTestModel(defaults: defaults, factory: factory)
        await model.start()
        XCTAssertEqual(model.phase, .onboarding)
        XCTAssertEqual(factory.configs.map(\.keepServerUrl), ["https://custom.keep.test"])
        XCTAssertEqual(factory.configs.map(\.serverUrl), ["http://localhost:8080"])
    }

    func testSignOutResetsKeepServerToAutomatic() async throws {
        let defaults = makeTestDefaults()
        KeepServer.store(.off, in: defaults)
        let factory = RecordingGimClientFactory()
        let model = makeTestModel(defaults: defaults, bundledKeepServerUrl: "https://keep.test", factory: factory)
        await model.start()
        try await model.createDemoIdentity(displayName: "Keep user")
        XCTAssertEqual(model.phase, .ready)

        let error = await model.signOut()
        XCTAssertNil(error)
        XCTAssertEqual(KeepServer.load(from: defaults), .automatic)
        XCTAssertEqual(factory.configs.map(\.keepServerUrl), [nil, "https://keep.test"])
        XCTAssertEqual(model.keepServerUrl, "https://keep.test")
    }

    func testKeepServerViewModelReportsRunningClient() async {
        let defaults = makeTestDefaults()
        KeepServer.store(.custom("https://custom.keep.test"), in: defaults)
        let model = makeTestModel(defaults: defaults, bundledKeepServerUrl: "https://keep.test")
        await model.start()
        let viewModel = model.makeKeepServerViewModel()
        XCTAssertEqual(viewModel.activeUrl, model.keepServerUrl)
        XCTAssertEqual(viewModel.defaultUrl, "https://keep.test")
        XCTAssertFalse(viewModel.needsRestart)
    }

    func testSignInAdoptsRegistrationKeepServer() async throws {
        let model = makeTestModel()
        await model.start()
        let config = ClientConfig(serverUrl: "http://signin.test", keepServerUrl: "https://keep.test")
        let client = try await FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
            .make(config: config, hooks: TestPlatformHooks())
        _ = try await client.createIdentity(displayName: "Sign-in user")
        let stored = try await client.session()
        let session = try XCTUnwrap(stored)
        model.signIn(Registration(client: client, config: config, session: session))
        XCTAssertEqual(model.keepServerUrl, "https://keep.test")
        XCTAssertEqual(model.makeKeepServerViewModel().activeUrl, "https://keep.test")
    }
}
