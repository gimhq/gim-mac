import GIMClientKit
import GIMFeatures
import SwiftUI

/// A chat's details; for groups also the name, members and leaving. Shown in a popover or sheet by the chat pane.
struct GroupInfoView: View {
    @State private var info: GroupInfoViewModel
    @State private var confirmsLeave = false
    @Environment(\.dismiss) private var dismiss

    init(client: any GimClientAPI, chatId: String) {
        _info = State(initialValue: GroupInfoViewModel(client: client, chatId: chatId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            Text("chat.info.title", tableName: "Chat")
                .font(.headline)
            header
            if info.isGroup {
                nameEditor
            }
            if let count = memberCount {
                Text(String(localized: "chat.info.members", defaultValue: "\(count) members", table: "Chat"))
                    .foregroundStyle(.secondary)
            }
            if info.membersUnavailable {
                Text("chat.info.membersUnavailable", tableName: "Chat")
                    .foregroundStyle(.secondary)
            }
            if let members = info.members {
                memberList(members)
            } else if info.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            if info.canEditMembers {
                addMemberRow
            }
            if let errorMessage = info.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Spacer(minLength: 0)
            if info.canLeave {
                Button(role: .destructive) {
                    confirmsLeave = true
                } label: {
                    Text("chat.info.leave", tableName: "Chat")
                }
                .disabled(info.isLeaving)
            }
        }
        .padding()
        .frame(minWidth: 320, minHeight: 360)
        .task {
            info.start()
            await info.load()
        }
        .onDisappear { info.stop() }
        .onChange(of: info.hasLeft) { _, hasLeft in
            if hasLeft { dismiss() }
        }
        .alert(
            Text(removalTitle), isPresented: removalPresented, presenting: info.pendingRemoval
        ) { member in
            Button(role: .destructive) {
                // Dismissing the alert clears `pendingRemoval` before the task runs; request it again first.
                Task {
                    info.requestRemoval(member)
                    await info.confirmRemoval()
                }
            } label: {
                Text("chat.info.remove.confirm", tableName: "Chat")
            }
            Button(role: .cancel) {
                info.cancelRemoval()
            } label: {
                Text("chat.info.cancel", tableName: "Chat")
            }
        }
        .alert(Text("chat.info.leave.title", tableName: "Chat"), isPresented: $confirmsLeave) {
            Button(role: .destructive) {
                Task { await info.leave() }
            } label: {
                Text("chat.info.leave.confirm", tableName: "Chat")
            }
            Button(role: .cancel) {
            } label: {
                Text("chat.info.cancel", tableName: "Chat")
            }
        } message: {
            Text("chat.info.leave.message", tableName: "Chat")
        }
    }

    private var title: String {
        UserLabel.name(info.summary?.name ?? "")
    }

    private var header: some View {
        HStack(spacing: DesignTokens.spacingM) {
            AvatarView(
                initials: SidebarRowModel.initials(for: title),
                colorIndex: SidebarRowModel.colorIndex(for: info.chatId),
                accessibilityTitle: title)
            Text(title)
                .font(.title3.bold())
        }
    }

    private var nameEditor: some View {
        HStack {
            TextField(text: $info.editedName, prompt: Text("chat.group.name.placeholder", tableName: "Chat")) {
                Text("chat.group.name.placeholder", tableName: "Chat")
            }
            .labelsHidden()
            .textFieldStyle(.roundedBorder)
            .disabled(!info.isActive)
            .onSubmit { Task { await info.saveName() } }
            Button {
                Task { await info.saveName() }
            } label: {
                Text("chat.info.name.save", tableName: "Chat")
            }
            .disabled(info.nameToSave == nil || info.isSavingName)
        }
    }

    private var memberCount: Int? {
        if let members = info.members { return members.count }
        return info.summary.map { Int($0.memberCount) }
    }

    private func memberList(_ members: [GroupInfoViewModel.Member]) -> some View {
        List(members) { member in
            HStack(spacing: DesignTokens.spacingS) {
                AvatarView(
                    initials: SidebarRowModel.initials(for: UserLabel.name(for: member.user)),
                    colorIndex: SidebarRowModel.colorIndex(for: member.user.userId),
                    accessibilityTitle: UserLabel.name(for: member.user),
                    size: DesignTokens.avatarSmall)
                VStack(alignment: .leading) {
                    Text(UserLabel.name(for: member.user))
                    Text(UserLabel.detail(for: member.user))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if member.isSelf {
                    Text("chat.info.you", tableName: "Chat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if info.canRemoveMembers && !member.isSelf {
                    Button {
                        info.requestRemoval(member)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                    .disabled(info.isUpdatingMembers)
                    .help(Text("chat.group.member.remove", tableName: "Chat"))
                    .accessibilityLabel(Text("chat.group.member.remove", tableName: "Chat"))
                }
            }
        }
    }

    private var addMemberRow: some View {
        HStack {
            TextField(text: $info.memberHandle, prompt: Text("chat.group.member.placeholder", tableName: "Chat")) {
                Text("chat.group.member.placeholder", tableName: "Chat")
            }
            .labelsHidden()
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .onSubmit { Task { await info.addMember() } }
            Button {
                Task { await info.addMember() }
            } label: {
                Text("chat.group.member.add", tableName: "Chat")
            }
            .disabled(info.memberHandle.isEmpty || info.isUpdatingMembers)
        }
    }

    private var removalPresented: Binding<Bool> {
        Binding(get: { info.pendingRemoval != nil }, set: { if !$0 { info.cancelRemoval() } })
    }

    private var removalTitle: String {
        let name = info.pendingRemoval.map { UserLabel.name(for: $0.user) } ?? ""
        return String(localized: "chat.info.remove.title", defaultValue: "Remove \(name) from the group?", table: "Chat")
    }
}
