/// Switches for settings that have a place in the window but are not offered yet.
enum SettingsFeatureFlags {
    /// Contract C7: the account-safety entries (avatar photo, privacy switches, blocked users, new recovery key,
    /// delete account). While `false` they are hidden; when shown they stay disabled and have no behaviour.
    static let accountSafety = false
}
