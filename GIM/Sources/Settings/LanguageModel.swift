import Foundation
import Observation

/// Settings → Language: the chosen language and whether the app has to restart to show it.
@MainActor
@Observable
final class LanguageModel {
    private(set) var choice: LanguageChoice
    /// The language the app is showing since it launched.
    let launchChoice: LanguageChoice

    var needsRelaunch: Bool { choice != launchChoice }

    @ObservationIgnored private let defaults: UserDefaults

    /// `launchChoice` defaults to the saved choice; `domain` is the persistent domain `defaults` writes to.
    init(
        defaults: UserDefaults = .standard, launchChoice: LanguageChoice? = nil,
        domain: String = Bundle.main.bundleIdentifier ?? ""
    ) {
        self.defaults = defaults
        let saved = LanguagePreference.choice(in: defaults, domain: domain)
        choice = saved
        self.launchChoice = launchChoice ?? saved
    }

    /// Saves the language; it shows after the next launch.
    func select(_ choice: LanguageChoice) {
        self.choice = choice
        LanguagePreference.apply(choice, to: defaults)
    }
}
