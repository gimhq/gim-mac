import GIMClientKit
import GIMFeatures
import SwiftUI

/// Collects a group name and members and creates the group.
struct NewGroupSheet: View {
    let starter: ChatStarter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var group = starter.newGroup
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            Text("chat.group.title", tableName: "Chat")
                .font(.title2.bold())
            TextField(text: $group.name, prompt: Text("chat.group.name.placeholder", tableName: "Chat")) {
                Text("chat.group.name.placeholder", tableName: "Chat")
            }
            .labelsHidden()
            .textFieldStyle(.roundedBorder)
            HStack {
                TextField(
                    text: $group.memberHandle, prompt: Text("chat.group.member.placeholder", tableName: "Chat")
                ) {
                    Text("chat.group.member.placeholder", tableName: "Chat")
                }
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .onSubmit { Task { await starter.newGroup.addMember() } }
                Button {
                    Task { await starter.newGroup.addMember() }
                } label: {
                    Text("chat.group.member.add", tableName: "Chat")
                }
                .disabled(group.memberHandle.isEmpty || group.isAddingMember)
            }
            if let memberError = group.memberError {
                errorText(memberError)
            }
            List(group.members, id: \.userId) { user in
                HStack(spacing: DesignTokens.spacingS) {
                    AvatarView(
                        initials: SidebarRowModel.initials(for: UserLabel.name(for: user)),
                        colorIndex: SidebarRowModel.colorIndex(for: user.userId),
                        accessibilityTitle: UserLabel.name(for: user),
                        size: DesignTokens.avatarSmall)
                    Text(UserLabel.name(for: user))
                    Text(UserLabel.shortUserId(user.userId))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        starter.newGroup.removeMember(user.userId)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .help(Text("chat.group.member.remove", tableName: "Chat"))
                    .accessibilityLabel(Text("chat.group.member.remove", tableName: "Chat"))
                }
            }
            if let validationMessage = group.validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let errorMessage = group.errorMessage {
                errorText(errorMessage)
            }
            HStack {
                Spacer()
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("chat.new.cancel", tableName: "Chat")
                }
                .keyboardShortcut(.cancelAction)
                Button {
                    Task { await starter.createGroup() }
                } label: {
                    Text("chat.group.create", tableName: "Chat")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!group.canCreate)
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 360)
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
    }
}
