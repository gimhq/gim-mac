import Foundation
import SwiftUI

/// A language the app can be shown in; the raw value is the `AppleLanguages` entry (`""` follows the Mac).
enum LanguageChoice: String, CaseIterable, Sendable {
    case system = ""
    case en
    /// zh-CN.
    case zhHans = "zh-Hans"
    /// zh-TW.
    case zhHant = "zh-Hant"
    case es

    /// Picker title in the `Settings` table; languages are named in their own language.
    var titleKey: LocalizedStringKey {
        switch self {
        case .system: "settings.language.system"
        case .en: "settings.language.en"
        case .zhHans: "settings.language.zhHans"
        case .zhHant: "settings.language.zhHant"
        case .es: "settings.language.es"
        }
    }

    /// The choice for an `AppleLanguages` entry such as "zh-CN" or "en-GB"; `nil` for other languages.
    init?(languageCode code: String) {
        if let exact = LanguageChoice(rawValue: code), exact != .system {
            self = exact
        } else if code.hasPrefix("zh-Hans") || code == "zh-CN" || code == "zh-SG" {
            self = .zhHans
        } else if code.hasPrefix("zh-Hant") || code == "zh-TW" || code == "zh-HK" || code == "zh-MO" {
            self = .zhHant
        } else if code.hasPrefix("en-") {
            self = .en
        } else if code.hasPrefix("es-") {
            self = .es
        } else {
            return nil
        }
    }
}

/// The app's language override, stored as `AppleLanguages` in the app's own defaults domain. It takes effect on the
/// next launch (`AppRelauncher`).
enum LanguagePreference {
    static let key = "AppleLanguages"

    /// The language set for the app in `domain` (the persistent domain `defaults` writes to); `.system` when none is
    /// set there or it is not one of the app's languages. The global domain's `AppleLanguages` is the Mac's own list
    /// and is ignored.
    static func choice(
        in defaults: UserDefaults, domain: String = Bundle.main.bundleIdentifier ?? ""
    ) -> LanguageChoice {
        guard let languages = defaults.persistentDomain(forName: domain)?[key] as? [String],
            let first = languages.first
        else { return .system }
        return LanguageChoice(languageCode: first) ?? .system
    }

    static func apply(_ choice: LanguageChoice, to defaults: UserDefaults) {
        if choice == .system {
            defaults.removeObject(forKey: key)
        } else {
            defaults.set([choice.rawValue], forKey: key)
        }
    }
}
