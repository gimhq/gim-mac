import XCTest

@testable import GIM

/// Every key the app uses has an English value in its String Catalog.
///
/// The catalogs are compiled into the app at build time, so the test resolves a static list of keys through the
/// test host's `Bundle.main` instead of parsing the `.xcstrings` files. Keep the map in sync with
/// `GIM/Resources/*.xcstrings`; W5's language test will replace it with a catalog-parsing test.
final class StringCatalogTests: XCTestCase {
    static let keysByTable: [String: [String]] = [
        "App": [
            "app.launch.loading",
            "app.launch.tryAgain",
            "app.ready.placeholder",
            "app.menuBar.placeholder",
            "app.main.noChatSelected",
            "app.sidebar.loading",
            "app.sidebar.empty",
            "app.sidebar.openInNewWindow",
            "app.connection.connected",
            "app.connection.connecting",
            "app.connection.offline",
            "app.connection.syncing",
            "app.command.openInNewWindow",
            "app.command.nextChat",
            "app.command.previousChat",
            "app.command.selectChat",
        ],
        "Explainer": [
            "explainer.title",
            "explainer.intro.body",
            "explainer.noPhoneNumber.title",
            "explainer.noPhoneNumber.body",
            "explainer.onYourDevices.title",
            "explainer.onYourDevices.body",
            "explainer.lockedMessages.title",
            "explainer.lockedMessages.body",
            "explainer.accountId.title",
            "explainer.accountId.body",
            "explainer.recoveryKey.title",
            "explainer.recoveryKey.body",
        ],
        "Onboarding": [
            "onboarding.create.cancel",
            "onboarding.create.nameBody",
            "onboarding.create.nameLabel",
            "onboarding.create.nameTitle",
            "onboarding.create.submit",
            "onboarding.create.submitting",
            "onboarding.flow.tryAgain",
            "onboarding.intro.back",
            "onboarding.intro.getStarted",
            "onboarding.intro.next",
            "onboarding.intro.page",
            "onboarding.intro.skip",
            "onboarding.kit.accountId",
            "onboarding.kit.body",
            "onboarding.kit.checkBody",
            "onboarding.kit.checkError",
            "onboarding.kit.checkLabel",
            "onboarding.kit.checkTitle",
            "onboarding.kit.confirm",
            "onboarding.kit.copied",
            "onboarding.kit.copy",
            "onboarding.kit.fileNote",
            "onboarding.kit.fileTitle",
            "onboarding.kit.recoveryKey",
            "onboarding.kit.saveFailed",
            "onboarding.kit.saveFile",
            "onboarding.kit.saved",
            "onboarding.kit.showAgain",
            "onboarding.kit.title",
            "onboarding.link.backToStart",
            "onboarding.link.cancel",
            "onboarding.link.compareBody",
            "onboarding.link.compareTitle",
            "onboarding.link.copied",
            "onboarding.link.copyCode",
            "onboarding.link.match",
            "onboarding.link.mismatch",
            "onboarding.link.qrLabel",
            "onboarding.link.rejected",
            "onboarding.link.scanBody",
            "onboarding.link.scanTitle",
            "onboarding.link.showNewCode",
            "onboarding.link.starting",
            "onboarding.link.title",
            "onboarding.link.waiting",
            "onboarding.restore.body",
            "onboarding.restore.cancel",
            "onboarding.restore.codeHelp",
            "onboarding.restore.codeLabel",
            "onboarding.restore.continue",
            "onboarding.restore.doneBody",
            "onboarding.restore.doneTitle",
            "onboarding.restore.errorCode",
            "onboarding.restore.errorIncomplete",
            "onboarding.restore.errorNotRecognized",
            "onboarding.restore.errorUserId",
            "onboarding.restore.manualTitle",
            "onboarding.restore.pasteHelp",
            "onboarding.restore.pasteLabel",
            "onboarding.restore.revokeOthers",
            "onboarding.restore.revokeOthersHelp",
            "onboarding.restore.submit",
            "onboarding.restore.submitting",
            "onboarding.restore.title",
            "onboarding.restore.userIdHelp",
            "onboarding.restore.userIdLabel",
            "onboarding.server.apply",
            "onboarding.server.current",
            "onboarding.server.help",
            "onboarding.server.keep",
            "onboarding.server.label",
            "onboarding.server.placeholder",
            "onboarding.server.useAnother",
            "onboarding.start.body",
            "onboarding.start.create",
            "onboarding.start.dismiss",
            "onboarding.start.link",
            "onboarding.start.localStateReset",
            "onboarding.start.restore",
            "onboarding.username.body",
            "onboarding.username.help",
            "onboarding.username.label",
            "onboarding.username.save",
            "onboarding.username.skip",
            "onboarding.username.title",
            "onboarding.welcome.title",
        ],
        "Chat": [
            "chat.placeholder.comingSoon",
        ],
        "Settings": [
            "settings.window.title",
        ],
    ]

    func testEveryKeyHasAnEnglishValue() {
        for (table, keys) in Self.keysByTable {
            for key in keys {
                // `localizedString(forKey:value:table:)` returns the raw format string, so keys with `%@` placeholders
                // resolve without `String(format:)` consuming missing arguments; a missing key comes back unchanged.
                let value = Bundle.main.localizedString(forKey: key, value: nil, table: table)
                XCTAssertFalse(value.isEmpty, "\(table): \(key) is empty")
                XCTAssertNotEqual(value, key, "\(table): \(key) has no English value")
            }
        }
    }

    func testEveryTableIsCovered() {
        XCTAssertEqual(Set(Self.keysByTable.keys), ["App", "Explainer", "Onboarding", "Chat", "Settings"])
    }
}
