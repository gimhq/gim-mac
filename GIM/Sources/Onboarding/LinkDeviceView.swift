import AppKit
import GIMFeatures
import SwiftUI

/// New device side of a device link: shows the link code until the other device approved it, then has the user
/// compare the codes.
struct LinkDeviceView: View {
    @State private var viewModel: LinkThisDeviceViewModel
    @State private var copied = false
    private let onLeave: () -> Void

    init(context: OnboardingContext, onLeave: @escaping () -> Void) {
        _viewModel = State(initialValue: LinkThisDeviceViewModel(context: context))
        self.onLeave = onLeave
    }

    var body: some View {
        VStack(spacing: 16) {
            switch viewModel.step {
            case .starting:
                ProgressView()
                Text("onboarding.link.starting", tableName: "Onboarding")
                    .foregroundStyle(.secondary)
                cancelButton
            case .waiting(let qrString):
                waiting(qrString: qrString)
            case .comparing(let sas):
                comparing(sas: sas)
            case .failed(let message):
                Text(message)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    cancelButton
                    Button {
                        Task { await viewModel.start() }
                    } label: {
                        Text("onboarding.link.showNewCode", tableName: "Onboarding")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            case .rejected:
                Text("onboarding.link.rejected", tableName: "Onboarding")
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    onLeave()
                } label: {
                    Text("onboarding.link.backToStart", tableName: "Onboarding")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            case .linked:
                ProgressView()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(Text("onboarding.link.title", tableName: "Onboarding"))
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.start() }
        .onDisappear {
            Task { await viewModel.abandon() }
        }
    }

    private var cancelButton: some View {
        Button {
            onLeave()
        } label: {
            Text("onboarding.link.cancel", tableName: "Onboarding")
        }
        .keyboardShortcut(.cancelAction)
    }

    @ViewBuilder
    private func waiting(qrString: String) -> some View {
        Text("onboarding.link.scanTitle", tableName: "Onboarding")
            .font(.headline)
        Text("onboarding.link.scanBody", tableName: "Onboarding")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        QRCodeImage(text: qrString)
            .frame(width: 220, height: 220)
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator))
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("onboarding.link.waiting", tableName: "Onboarding")
                .foregroundStyle(.secondary)
        }
        HStack {
            cancelButton
            Button {
                copy(qrString)
            } label: {
                if copied {
                    Text("onboarding.link.copied", tableName: "Onboarding")
                } else {
                    Text("onboarding.link.copyCode", tableName: "Onboarding")
                }
            }
        }
    }

    @ViewBuilder
    private func comparing(sas: String) -> some View {
        Text("onboarding.link.compareTitle", tableName: "Onboarding")
            .font(.headline)
        Text("onboarding.link.compareBody", tableName: "Onboarding")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        Text(sas)
            .font(.system(size: 34, weight: .semibold, design: .monospaced))
            .textSelection(.enabled)
        if let error = viewModel.errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
        HStack {
            Button {
                Task { await viewModel.confirm(codesMatch: false) }
            } label: {
                Text("onboarding.link.mismatch", tableName: "Onboarding")
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)
            Button {
                Task { await viewModel.confirm(codesMatch: true) }
            } label: {
                Text("onboarding.link.match", tableName: "Onboarding")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(viewModel.isConfirming)
        }
    }

    private func copy(_ qrString: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(qrString, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }
}
