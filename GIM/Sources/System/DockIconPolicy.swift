import AppKit

/// Shows or hides the Dock icon (menu bar mode) through the activation policy.
@MainActor
enum DockIconPolicy {
    static func apply(hidden: Bool) {
        let wasHidden = NSApp.activationPolicy() == .accessory
        NSApp.setActivationPolicy(hidden ? .accessory : .regular)
        // Back to `.regular`: bring the Dock icon and the windows to the front again.
        if !hidden, wasHidden {
            NSApp.activate()
        }
    }
}
