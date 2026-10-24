import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class OnboardingErrorTextTests: XCTestCase {
    /// `text` is a catalog value, not a missing key echoed back.
    private func assertLocalized(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(text.isEmpty, file: file, line: line)
        XCTAssertFalse(text.hasPrefix("onboarding."), "missing catalog key: \(text)", file: file, line: line)
    }

    func testServerUrlKinds() {
        assertLocalized(OnboardingErrorText.serverUrl(.empty))
        assertLocalized(OnboardingErrorText.serverUrl(.notAFullAddress))
        XCTAssertEqual(OnboardingErrorText.serverUrl(.empty), "Enter the server address.")
    }

    func testDisplayNameKinds() {
        assertLocalized(OnboardingErrorText.displayName(.empty))
        assertLocalized(OnboardingErrorText.displayName(.tooLong))
    }

    func testHandleKinds() {
        assertLocalized(OnboardingErrorText.handle(.empty))
        assertLocalized(OnboardingErrorText.handle(.length))
        assertLocalized(OnboardingErrorText.handle(.characters))
    }

    func testClaimHandleKinds() {
        assertLocalized(OnboardingErrorText.claimHandle(.taken))
        XCTAssertEqual(OnboardingErrorText.claimHandle(.error(.network)), ErrorPresenter.text(for: .network))
    }

    func testRestoreKinds() {
        let kinds: [RestoreViewModel.ErrorKind] = [
            .notFound, .wrongCode, .userIdMissing, .recoveryCodeMissing, .kitNotRecognized, .kitPartMissing,
        ]
        for kind in kinds {
            assertLocalized(OnboardingErrorText.restore(kind))
        }
        XCTAssertEqual(Set(kinds.map(OnboardingErrorText.restore)).count, kinds.count)
        XCTAssertEqual(OnboardingErrorText.restore(.error(.network)), ErrorPresenter.text(for: .network))
    }

    func testEndingKind() {
        assertLocalized(OnboardingErrorText.ending(.mismatch))
    }
}
