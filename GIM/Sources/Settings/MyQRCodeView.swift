import SwiftUI

/// Sheet with the QR code of the Account ID (contract C8) for a friend to scan.
struct MyQRCodeView: View {
    let accountId: String

    @Environment(\.dismiss) private var dismiss

    private static let side: CGFloat = 240

    var body: some View {
        VStack(spacing: DesignTokens.spacingL) {
            Text("settings.profile.myQRCode", tableName: "Settings")
                .font(.headline)
            if let image = AccountQRCode.image(payload: AccountQRCode.payload(accountId: accountId), side: Self.side) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: Self.side, height: Self.side)
                    .accessibilityLabel(Text("settings.profile.qrAccessibility", tableName: "Settings"))
            }
            Text(verbatim: accountId)
                .font(.body.monospaced())
                .textSelection(.enabled)
            Text("settings.profile.qrHelp", tableName: "Settings")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                dismiss()
            } label: {
                Text("settings.profile.done", tableName: "Settings")
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(DesignTokens.spacingL)
        .frame(minWidth: 320)
    }
}
