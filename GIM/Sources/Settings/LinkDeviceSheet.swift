import GIMClientKit
import GIMFeatures
import SwiftUI

/// Links a new device from this Mac: paste its link code, compare the numbers, then the new device is added or not.
///
/// Closing the sheet after approving without a decision removes the half-linked device (`abandon()`).
struct LinkDeviceSheet: View {
    /// Called once the new device was linked, so the device list can reload.
    let onLinked: @MainActor () -> Void

    @State private var link: ApproveLinkViewModel
    @State private var showsEmptyCodeError = false
    @Environment(\.dismiss) private var dismiss

    init(client: any GimClientAPI, onLinked: @escaping @MainActor () -> Void) {
        self.onLinked = onLinked
        _link = State(initialValue: ApproveLinkViewModel(client: client))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            Text("settings.link.title", tableName: "Settings")
                .font(.title2)
            if let outcome = link.outcome {
                result(outcome)
            } else if let sas = link.sas {
                compare(sas)
            } else {
                enterCode
            }
            if let error = link.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
        .padding(DesignTokens.spacingL)
        .frame(width: 420)
        .onChange(of: link.outcome) { _, outcome in
            if outcome == .linked { onLinked() }
        }
        .onDisappear {
            guard link.sas != nil, link.outcome == nil else { return }
            Task { await link.abandon() }
        }
    }

    private var enterCode: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            Text("settings.link.instructions", tableName: "Settings")
                .fixedSize(horizontal: false, vertical: true)
            TextField(
                String(localized: "settings.link.codePlaceholder", table: "Settings"),
                text: Bindable(link).linkCode)
                .autocorrectionDisabled()
                .onSubmit(submit)
            if showsEmptyCodeError {
                Text("settings.link.emptyCode", tableName: "Settings")
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("settings.link.cancel", tableName: "Settings")
                }
                .keyboardShortcut(.cancelAction)
                Button(action: submit) {
                    Text("settings.link.continue", tableName: "Settings")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!link.canApprove)
            }
        }
    }

    private func compare(_ sas: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            Text(verbatim: sas)
                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity)
            Text("settings.link.compare", tableName: "Settings")
            HStack {
                Spacer()
                Button(role: .destructive) {
                    Task { await link.confirm(codesMatch: false) }
                } label: {
                    Text("settings.link.noMatch", tableName: "Settings")
                }
                Button {
                    Task { await link.confirm(codesMatch: true) }
                } label: {
                    Text("settings.link.match", tableName: "Settings")
                }
                .keyboardShortcut(.defaultAction)
            }
            .disabled(link.isWorking)
        }
    }

    private func result(_ outcome: ApproveLinkViewModel.Outcome) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            switch outcome {
            case .linked: Text("settings.link.linked", tableName: "Settings")
            case .rejected: Text("settings.link.rejected", tableName: "Settings")
            }
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("settings.link.done", tableName: "Settings")
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    /// Approves the pasted code; an empty code gets this sheet's own message instead of the view model's.
    private func submit() {
        let code = link.linkCode.trimmingCharacters(in: .whitespacesAndNewlines)
        showsEmptyCodeError = code.isEmpty
        guard !code.isEmpty else { return }
        Task { await link.submit() }
    }
}
