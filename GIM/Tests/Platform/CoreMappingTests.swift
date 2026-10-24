import GIMClientKit
import GIMCore
import XCTest

@testable import GIM

final class CoreMappingTests: XCTestCase {
    func testClientConfigKeepsTheMode() {
        XCTAssertEqual(
            GIMCore.ClientConfig(GIMClientKit.ClientConfig(serverUrl: "https://gim.example.eu")),
            GIMCore.ClientConfig(serverUrl: "https://gim.example.eu", mode: nil, metaServerUrl: nil))
        XCTAssertEqual(
            GIMCore.ClientConfig(GIMClientKit.ClientConfig(serverUrl: "https://gim.example.eu", mode: .app)).mode,
            .app)
        XCTAssertEqual(
            GIMCore.ClientConfig(GIMClientKit.ClientConfig(serverUrl: "https://gim.example.eu", mode: .extension)).mode,
            .extension)
    }

    func testUserSuspendedMapsBothWays() {
        XCTAssertEqual(
            GIMClientKit.GimError(GIMCore.GimError.UserSuspended(hubId: "hub-a")), .UserSuspended(hubId: "hub-a"))
        XCTAssertEqual(GIMCore.GimError(GIMClientKit.GimError.UserSuspended(hubId: "")), .UserSuspended(hubId: ""))
    }

    func testUserPolicyErrorsMapBothWays() {
        let cases: [(GIMCore.GimError, GIMClientKit.GimError)] = [
            (.UserNotAdmitted(hubId: "hub-a"), .UserNotAdmitted(hubId: "hub-a")),
            (.UserNotAdmitted(hubId: ""), .UserNotAdmitted(hubId: "")),
            (
                .NotAdmittedByPeer(hubId: "hub-b", chatId: "hub-b/g1"),
                .NotAdmittedByPeer(hubId: "hub-b", chatId: "hub-b/g1")
            ),
            (.ContactNotAdmitted(userIds: ["u1", "u2"]), .ContactNotAdmitted(userIds: ["u1", "u2"])),
        ]
        for (core, mirror) in cases {
            XCTAssertEqual(GIMClientKit.GimError(core), mirror)
            XCTAssertEqual(GIMCore.GimError(mirror), core)
        }
    }

    func testFailedSendStateKeepsTheReasonAndCause() {
        let causes: [(GIMCore.SendFailure, GIMClientKit.SendFailure)] = [
            (.userSuspended, .userSuspended), (.userNotAdmitted, .userNotAdmitted),
            (.notAdmittedByPeer, .notAdmittedByPeer), (.rejected, .rejected), (.other, .other),
        ]
        for (core, mirror) in causes {
            XCTAssertEqual(GIMClientKit.SendFailure(core), mirror)
            XCTAssertEqual(
                GIMClientKit.SendState(GIMCore.SendState.failed(reason: "refused", cause: core)),
                .failed(reason: "refused", cause: mirror))
        }
    }

    func testPushRegistrationMapsEveryField() {
        let mirror = GIMClientKit.PushRegistration(
            provider: "unifiedpush", token: "https://push.example.eu/up/abc", appId: "im.g.apps", sandbox: false,
            p256dh: "BNcR", auth: "tBHI")
        XCTAssertEqual(
            GIMCore.PushRegistration(mirror),
            GIMCore.PushRegistration(
                provider: "unifiedpush", token: "https://push.example.eu/up/abc", appId: "im.g.apps", sandbox: false,
                p256dh: "BNcR", auth: "tBHI"))
    }

    func testNotificationContentMapsEveryFieldAndKind() {
        let kinds: [(GIMCore.NotificationKind, GIMClientKit.NotificationKind)] = [
            (.message, .message), (.reaction, .reaction), (.invite, .invite), (.membership, .membership),
            (.generic, .generic),
        ]
        for (core, mirror) in kinds {
            let content = GIMCore.NotificationContent(
                chatId: "chat-crew", chatTitle: "Aegean Crew", senderUserId: "user-sofia",
                senderDisplayName: "Sofia Marin", body: "Anchored in Hydra", messageId: "msg-1",
                collapseId: "collapse-1", kind: core, shouldDisplay: core != .membership,
                timestamp: 1_790_000_000_000)
            XCTAssertEqual(
                GIMClientKit.NotificationContent(content),
                GIMClientKit.NotificationContent(
                    chatId: "chat-crew", chatTitle: "Aegean Crew", senderUserId: "user-sofia",
                    senderDisplayName: "Sofia Marin", body: "Anchored in Hydra", messageId: "msg-1",
                    collapseId: "collapse-1", kind: mirror, shouldDisplay: mirror != .membership,
                    timestamp: 1_790_000_000_000))
        }
    }

    func testEveryCoreErrorMapsToTheMirror() {
        let cases: [(GIMCore.GimError, GIMClientKit.GimError)] = [
            (.Network(reason: "down"), .Network(reason: "down")),
            (.NotRegistered, .NotRegistered),
            (.InvalidInput(reason: "bad"), .InvalidInput(reason: "bad")),
            (.NotFound(reason: "gone"), .NotFound(reason: "gone")),
            (.Crypto(reason: "mls"), .Crypto(reason: "mls")),
            (.Storage(reason: "disk"), .Storage(reason: "disk")),
            (.Server(status: 409, reason: "taken"), .Server(status: 409, reason: "taken")),
            (
                .RetryLater(status: 429, retryAfterSecs: 30, reason: "rate_limited"),
                .RetryLater(status: 429, retryAfterSecs: 30, reason: "rate_limited")
            ),
            (.Cancelled, .Cancelled),
            (.NotImplemented, .NotImplemented),
            (.Internal(reason: "bug"), .Internal(reason: "bug")),
            (.ChatNotActive(chatId: "c1", state: .leaving), .ChatNotActive(chatId: "c1", state: .leaving)),
            (.HubNotVerified(reason: "tls"), .HubNotVerified(reason: "tls")),
            (.HubOwnsGroups(hubId: "hub-a", groupCount: 2), .HubOwnsGroups(hubId: "hub-a", groupCount: 2)),
            (.LastHub(hubId: "hub-a"), .LastHub(hubId: "hub-a")),
            (.HomeHub(hubId: "hub-a"), .HomeHub(hubId: "hub-a")),
            (.HubNotDrained(hubId: "hub-a", reason: "outbox"), .HubNotDrained(hubId: "hub-a", reason: "outbox")),
        ]
        for (core, mirror) in cases {
            XCTAssertEqual(GIMClientKit.GimError(core), mirror)
            XCTAssertEqual(GIMCore.GimError(mirror), core)
        }
    }

    func testBridgedRethrowsCoreErrorsAsTheMirror() async {
        do {
            _ = try await bridged { () async throws -> Int in throw GIMCore.GimError.NotFound(reason: "chat") }
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? GIMClientKit.GimError, .NotFound(reason: "chat"))
        }
        XCTAssertThrowsError(try bridgedSync { () throws -> Int in throw CocoaError(.fileNoSuchFile) }) { error in
            guard case .Internal = error as? GIMClientKit.GimError else {
                return XCTFail("expected Internal, got \(error)")
            }
        }
    }

    func testChatSummaryKeepsTheMirroredFields() {
        let sender = GIMCore.UserProfile(userId: "user-sofia", handle: "sofia", displayName: "Sofia", hasAvatar: true)
        let media = GIMCore.MediaRef(
            chatId: "chat-crew", messageId: "msg-0", mime: "image/png", size: 1024, hasThumbnail: true)
        let core = GIMCore.ChatSummary(
            chatId: "chat-crew", kind: .group, name: "Aegean Crew", avatar: media,
            lastMessage: GIMCore.MessagePreview(
                senderName: "Sofia", text: "Photo", sentAtMs: 5, isOwn: true, sendState: .delivered),
            unreadCount: 3, updatedAtMs: 7, memberCount: 4, state: .active, peer: sender, mutedUntilMs: 9,
            pinned: true, archived: false, blocked: false)
        XCTAssertEqual(
            GIMClientKit.ChatSummary(core),
            GIMClientKit.ChatSummary(
                chatId: "chat-crew", kind: .group, name: "Aegean Crew",
                avatar: GIMClientKit.MediaRef(
                    chatId: "chat-crew", messageId: "msg-0", mime: "image/png", size: 1024, hasThumbnail: true),
                lastMessage: GIMClientKit.MessagePreview(senderName: "Sofia", text: "Photo", sentAtMs: 5, isOwn: true),
                unreadCount: 3, updatedAtMs: 7, memberCount: 4, state: .active))
        XCTAssertEqual(
            GIMClientKit.UserProfile(sender),
            GIMClientKit.UserProfile(userId: "user-sofia", handle: "sofia", displayName: "Sofia"))
    }

    func testTimelineDiffMapsMessagesSeparatorsAndMembership() {
        let sender = GIMCore.UserProfile(userId: "user-sofia", handle: "sofia", displayName: "Sofia", hasAvatar: false)
        let message = GIMCore.MessageItem(
            messageId: "msg-1", chatId: "chat-crew", sender: sender, isOwn: false, sentAtMs: 10,
            content: .file(
                media: GIMCore.MediaRef(
                    chatId: "chat-crew", messageId: "msg-1", mime: "application/pdf", size: 2, hasThumbnail: false),
                fileName: "route.pdf", caption: nil),
            replyTo: GIMCore.ReplyPreview(messageId: "msg-0", senderName: "Nikos", text: "Where?"),
            reactions: [GIMCore.ReactionGroup(emoji: "👍", count: 2, own: true)], edited: true,
            sendState: nil)
        let diffs = GIMCore.TimelineDiff.reset(values: [
            .dateSeparator(dayStartMs: 0),
            .message(item: message),
            .membershipChange(userName: "Nikos", change: .left, atMs: 11, userId: "user-nikos", actorUserId: nil),
        ])
        let mirrorSender = GIMClientKit.UserProfile(userId: "user-sofia", handle: "sofia", displayName: "Sofia")
        XCTAssertEqual(
            GIMClientKit.TimelineDiff(diffs),
            .reset(values: [
                .dateSeparator(dayStartMs: 0),
                .message(
                    item: GIMClientKit.MessageItem(
                        messageId: "msg-1", chatId: "chat-crew", sender: mirrorSender, isOwn: false, sentAtMs: 10,
                        content: .file(
                            media: GIMClientKit.MediaRef(
                                chatId: "chat-crew", messageId: "msg-1", mime: "application/pdf", size: 2,
                                hasThumbnail: false),
                            fileName: "route.pdf", caption: nil),
                        replyTo: GIMClientKit.ReplyPreview(messageId: "msg-0", senderName: "Nikos", text: "Where?"),
                        reactions: [GIMClientKit.ReactionGroup(emoji: "👍", count: 2, own: true)], edited: true,
                        sendState: nil)),
                .membershipChange(
                    userName: "Nikos", change: .left, atMs: 11, userId: "user-nikos", actorUserId: nil),
            ]))
        XCTAssertEqual(GIMClientKit.TimelineDiff(GIMCore.TimelineDiff.truncate(length: 4)), .truncate(length: 4))
    }

    func testEnumsMapOneToOne() {
        XCTAssertEqual(GIMClientKit.ConnectionState(GIMCore.ConnectionState.syncing), .syncing)
        XCTAssertEqual(GIMClientKit.HubState(GIMCore.HubState.removed), .removed)
        XCTAssertEqual(GIMClientKit.ChatKind(GIMCore.ChatKind.direct), .direct)
        XCTAssertEqual(GIMCore.ChatState(GIMClientKit.ChatState.left), .left)
        XCTAssertEqual(GIMClientKit.ChatState(GIMCore.ChatState.leaving), .leaving)
        XCTAssertEqual(
            GIMClientKit.HubInfo(
                GIMCore.HubInfo(
                    hubId: "hub-a", url: nil, state: .verified, priority: 1, isPrimary: false, isHome: true,
                    signedIn: true)),
            GIMClientKit.HubInfo(
                hubId: "hub-a", url: nil, state: .verified, priority: 1, isPrimary: false, isHome: true,
                signedIn: true))
    }
}
