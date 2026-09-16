import OpenDockCore
import SwiftUI

@MainActor
struct EditorView: View {
    var session: LibrarySession
    @State private var selectedProfileID: UUID?
    @State private var nameDraft = ""
    @State private var linkTitle = ""
    @State private var linkURL = ""
    @State private var pathTitle = ""
    @State private var pathValue = ""

    var body: some View {
        HSplitView {
            profileList
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 260)
            tilePane
                .frame(minWidth: 320, idealWidth: 400)
        }
        .frame(minWidth: 560, minHeight: 360)
        .onAppear {
            selectedProfileID = session.activeProfile?.id ?? session.profiles.first?.id
            syncNameDraft()
        }
        .onChange(of: session.library) { _, _ in
            if let selectedProfileID, session.profiles.contains(where: { $0.id == selectedProfileID }) {
                return
            }
            selectedProfileID = session.activeProfile?.id ?? session.profiles.first?.id
            syncNameDraft()
        }
        .onChange(of: selectedProfileID) { _, _ in
            syncNameDraft()
        }
    }

    private var selectedProfile: Profile? {
        session.profiles.first(where: { $0.id == selectedProfileID })
    }

    private var profileList: some View {
        VStack(alignment: .leading, spacing: 0) {
            List(selection: $selectedProfileID) {
                ForEach(session.profiles) { profile in
                    HStack {
                        Text(profile.name)
                        if profile.id == session.library.activeProfileID {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                                .imageScale(.small)
                        }
                    }
                    .tag(profile.id)
                    .contextMenu {
                        Button("Use this profile") {
                            session.setActive(profile.id)
                        }
                        Button("Remove", role: .destructive) {
                            session.removeProfile(id: profile.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            HStack {
                Button("Add Profile") {
                    session.addProfile(name: "Untitled")
                    selectedProfileID = session.activeProfile?.id
                }
                Button("Remove", role: .destructive) {
                    guard let id = selectedProfileID else { return }
                    session.removeProfile(id: id)
                }
                .disabled(selectedProfileID == nil)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
        }
    }

    private var tilePane: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let profile = selectedProfile {
                HStack {
                    TextField("Profile name", text: $nameDraft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            session.renameProfile(id: profile.id, to: nameDraft)
                        }
                    Button("Use") {
                        session.setActive(profile.id)
                    }
                    .disabled(profile.id == session.library.activeProfileID)
                }

                List {
                    ForEach(profile.tiles) { tile in
                        HStack {
                            Image(systemName: iconName(for: tile.kind))
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rowTitle(for: tile))
                                Text(rowDetail(for: tile))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button("Remove") {
                                session.removeTile(id: tile.id, from: profile.id)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Link title", text: $linkTitle)
                        TextField("https://", text: $linkURL)
                        Button("Add Link") {
                            session.addLink(title: linkTitle, urlString: linkURL, to: profile.id)
                            linkTitle = ""
                            linkURL = ""
                        }
                        .disabled(linkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    HStack {
                        TextField("Path title", text: $pathTitle)
                        TextField("~/Projects/repo", text: $pathValue)
                        Button("Choose…") {
                            if let url = AppPrompts.choosePath() {
                                pathTitle = url.lastPathComponent
                                pathValue = url.path
                            }
                        }
                        Button("Add Path") {
                            session.addPath(title: pathTitle, path: pathValue, to: profile.id)
                            pathTitle = ""
                            pathValue = ""
                        }
                        .disabled(pathValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Button("Add Spacer") {
                        session.addSpacer(to: profile.id)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Profile",
                    systemImage: "rectangle.stack",
                    description: Text("Add a profile to pin links and folders.")
                )
            }

            if let lastError = session.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
    }

    private func syncNameDraft() {
        nameDraft = selectedProfile?.name ?? ""
    }

    private func iconName(for kind: TileKind) -> String {
        switch kind {
        case .link: "link"
        case .path: "folder"
        case .spacer: "minus"
        }
    }

    private func rowTitle(for tile: Tile) -> String {
        switch tile.kind {
        case .spacer: "Spacer"
        case .link, .path: tile.title
        }
    }

    private func rowDetail(for tile: Tile) -> String {
        switch tile.kind {
        case .link(let url): url.absoluteString
        case .path(let path): path
        case .spacer: "Gap"
        }
    }
}
