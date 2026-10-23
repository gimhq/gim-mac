import Foundation

/// One section of "How gim works". The keys live in the `Explainer` String Catalog.
struct ExplainerSection: Identifiable, Hashable, Sendable {
    let id: String
    let titleKey: String.LocalizationValue?
    let bodyKey: String.LocalizationValue

    /// The resolved title, or nil for the untitled intro.
    func title() -> String? {
        titleKey.map { String(localized: $0, table: "Explainer") }
    }

    /// The resolved body.
    func body() -> String {
        String(localized: bodyKey, table: "Explainer")
    }
}

/// The six "How gim works" sections, shared by the onboarding intro pages and the Help window.
enum ExplainerContent {
    static let title: String.LocalizationValue = "explainer.title"

    static let sections: [ExplainerSection] = [
        ExplainerSection(id: "intro", titleKey: nil, bodyKey: "explainer.intro.body"),
        ExplainerSection(
            id: "noPhoneNumber", titleKey: "explainer.noPhoneNumber.title", bodyKey: "explainer.noPhoneNumber.body"),
        ExplainerSection(
            id: "onYourDevices", titleKey: "explainer.onYourDevices.title", bodyKey: "explainer.onYourDevices.body"),
        ExplainerSection(
            id: "lockedMessages", titleKey: "explainer.lockedMessages.title", bodyKey: "explainer.lockedMessages.body"),
        ExplainerSection(id: "accountId", titleKey: "explainer.accountId.title", bodyKey: "explainer.accountId.body"),
        ExplainerSection(
            id: "recoveryKey", titleKey: "explainer.recoveryKey.title", bodyKey: "explainer.recoveryKey.body"),
    ]
}
