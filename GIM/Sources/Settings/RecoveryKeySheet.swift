import AppKit
import GIMClientKit
import GIMFeatures
import SwiftUI

/// Settings → Account and devices → Show recovery key. Shows nothing until the Mac's owner authenticated; the sheet's
/// window is left out of screenshots and screen recordings, and the key is hidden again when the window stops being
/// key, is minimized, the app is deactivated or the sheet closes. A Mac without the key offers a new one.
struct RecoveryKeySheet: View {
    @Bindable var viewModel: RecoveryKeyViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    @State private var saveError: String?
    /// The save panel takes the key window; that must not hide the key it is saving.
    @State private var isSaving = false

    private static let qrSide: CGFloat = 200

    var body: some View {
        VStack(spacing: DesignTokens.spacingL) {
            Text("settings.recoveryKey.title", tableName: "Settings")
                .font(.title2.bold())
            content
        }
        .padding(DesignTokens.spacingL)
        .frame(minWidth: 460)
        .background(
            CaptureProtection {
                if viewModel.state == .shown, !isSaving { viewModel.hide() }
            }
        )
        .onDisappear { viewModel.hide() }
    }

    @ViewBuilder
    private var content: some View {
        if let kit = viewModel.rotation.kit {
            RecoveryKitView(viewModel: kit)
        } else {
            switch viewModel.state {
            case .locked, .authenticating:
                locked
            case .shown:
                shown
            case .notOnThisDevice:
                notOnThisDevice
            }
        }
    }

    @ViewBuilder
    private var locked: some View {
        Text("settings.recoveryKey.lockedBody", tableName: "Settings")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        errorText(viewModel.errorMessage)
        HStack {
            doneButton
            Button {
                Task { await viewModel.reveal() }
            } label: {
                Text("settings.recoveryKey.show", tableName: "Settings")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(viewModel.state == .authenticating)
        }
    }

    @ViewBuilder
    private var shown: some View {
        Text("settings.recoveryKey.shownBody", tableName: "Settings")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        Text(verbatim: viewModel.groupedCode)
            .font(.system(.title3, design: .monospaced))
            .textSelection(.enabled)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(DesignTokens.spacingM)
            .frame(maxWidth: .infinity)
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius).strokeBorder(.separator))
        if let image = AccountQRCode.image(payload: viewModel.kitText, side: Self.qrSide) {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .frame(width: Self.qrSide, height: Self.qrSide)
                .accessibilityLabel(Text("settings.recoveryKey.qrAccessibility", tableName: "Settings"))
        }
        errorText(saveError)
        HStack {
            Button(action: copy) {
                if copied {
                    Text("settings.recoveryKey.copied", tableName: "Settings")
                } else {
                    Text("settings.recoveryKey.copy", tableName: "Settings")
                }
            }
            Button(action: save) {
                Text("settings.recoveryKey.save", tableName: "Settings")
            }
            doneButton
                .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var notOnThisDevice: some View {
        let rotation = viewModel.rotation
        Text("settings.recoveryKey.notOnDevice", tableName: "Settings")
            .font(.headline)
            .multilineTextAlignment(.center)
        switch rotation.state {
        case .confirming:
            VStack(spacing: DesignTokens.spacingS) {
                Text("settings.recoveryKey.confirmTitle", tableName: "Settings")
                    .font(.headline)
                Text("settings.recoveryKey.confirmBody", tableName: "Settings")
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button {
                    rotation.cancel()
                } label: {
                    Text("settings.recoveryKey.cancel", tableName: "Settings")
                }
                .keyboardShortcut(.cancelAction)
                Button {
                    Task { await rotation.rotate() }
                } label: {
                    Text("settings.recoveryKey.create", tableName: "Settings")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        case .rotating, .showingKit:
            HStack(spacing: DesignTokens.spacingS) {
                ProgressView()
                    .controlSize(.small)
                Text("settings.recoveryKey.creating", tableName: "Settings")
            }
        case .idle, .failed:
            Text("settings.recoveryKey.notOnDeviceBody", tableName: "Settings")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if case .failed(let message) = rotation.state {
                errorText(message)
            }
            if rotation.hasUnsyncedServers {
                Text("settings.recoveryKey.unsynced", tableName: "Settings")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            HStack {
                doneButton
                Button {
                    rotation.start()
                } label: {
                    Text("settings.recoveryKey.create", tableName: "Settings")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var doneButton: some View {
        Button {
            viewModel.hide()
            dismiss()
        } label: {
            Text("settings.recoveryKey.done", tableName: "Settings")
        }
        .keyboardShortcut(.cancelAction)
    }

    @ViewBuilder
    private func errorText(_ message: String?) -> some View {
        if let message {
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(viewModel.kitText, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }

    private func save() {
        isSaving = true
        defer { isSaving = false }
        saveError =
            RecoveryKitFile.save(viewModel.kitText) == nil
            ? nil : String(localized: "settings.recoveryKey.saveFailed", table: "Settings")
    }
}

/// Keeps the hosting window out of screenshots and screen recordings (`NSWindow.sharingType = .none`) and calls
/// `onConceal` when the window resigns key or is minimized (it or its sheet parent) and when the app is deactivated.
struct CaptureProtection: NSViewRepresentable {
    let onConceal: @MainActor () -> Void

    func makeNSView(context: Context) -> ProtectedView {
        ProtectedView(onConceal: onConceal)
    }

    func updateNSView(_ view: ProtectedView, context: Context) {
        view.onConceal = onConceal
    }

    final class ProtectedView: NSView {
        var onConceal: @MainActor () -> Void

        init(onConceal: @escaping @MainActor () -> Void) {
            self.onConceal = onConceal
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            let center = NotificationCenter.default
            center.removeObserver(self)
            guard let window else { return }
            window.sharingType = .none
            let conceal = #selector(conceal(_:))
            center.addObserver(self, selector: conceal, name: NSWindow.didResignKeyNotification, object: window)
            center.addObserver(self, selector: conceal, name: NSWindow.didMiniaturizeNotification, object: window)
            if let parent = window.sheetParent {
                center.addObserver(self, selector: conceal, name: NSWindow.didMiniaturizeNotification, object: parent)
            }
            center.addObserver(self, selector: conceal, name: NSApplication.didResignActiveNotification, object: nil)
        }

        @objc private func conceal(_ notification: Notification) {
            onConceal()
        }
    }
}
