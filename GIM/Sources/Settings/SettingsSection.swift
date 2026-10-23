/// The sections of the Settings window, in sidebar order.
enum SettingsSection: String, CaseIterable, Identifiable, Sendable {
    case profile
    case accountDevices
    case notifications
    case appearance
    case language
    case advanced
    case helpAbout

    var id: String { rawValue }

    /// Key of the section title in the `Settings` table.
    var titleKey: String { "settings.section.\(rawValue)" }

    var systemImage: String {
        switch self {
        case .profile: "person.crop.circle"
        case .accountDevices: "laptopcomputer.and.iphone"
        case .notifications: "bell"
        case .appearance: "paintpalette"
        case .language: "globe"
        case .advanced: "gearshape.2"
        case .helpAbout: "questionmark.circle"
        }
    }
}
