import AppKit
import OpenDockCore
import SwiftUI

@MainActor
struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    var session: LibrarySession
    var panelController: DockPanelController

    var body: some View {
        ForEach(session.profiles) { profile in
            Button {
                session.setActive(profile.id)
                panelController.refresh()
            } label: {
                if profile.id == session.library.activeProfileID {
                    Label(profile.name, systemImage: "checkmark")
                } else {
                    Text(profile.name)
                }
            }
        }

        if session.profiles.isEmpty {
            Text("No profiles")
                .foregroundStyle(.secondary)
        }

        Divider()

        Button("Show Dock") {
            panelController.show()
        }

        Divider()

        Button("New Profile…") {
            if let name = AppPrompts.askText(
                title: "New Profile",
                message: "Name a profile for a project you work on.",
                placeholder: "Profile name"
            ) {
                session.addProfile(name: name)
                panelController.refresh()
            }
        }

        Button("Remove Profile") {
            guard let profile = session.activeProfile else { return }
            let confirmed = AppPrompts.confirm(
                title: "Remove “\(profile.name)”?",
                message: "Tiles in this profile will be deleted from the library.",
                confirm: "Remove"
            )
            if confirmed {
                session.removeProfile(id: profile.id)
                panelController.refresh()
            }
        }
        .disabled(session.activeProfile == nil)

        Divider()

        Button("New Link…") {
            guard let profileID = session.activeProfile?.id else { return }
            if let fields = AppPrompts.askTwoFields(
                title: "New Link",
                message: "Pin a URL to the active profile.",
                firstPlaceholder: "Title",
                secondPlaceholder: "https://"
            ) {
                session.addLink(title: fields.0, urlString: fields.1, to: profileID)
                panelController.refresh()
            }
        }
        .disabled(session.activeProfile == nil)

        Button("New Path…") {
            guard let profileID = session.activeProfile?.id else { return }
            if let url = AppPrompts.choosePath() {
                session.addPath(title: url.lastPathComponent, path: url.path, to: profileID)
                panelController.refresh()
            }
        }
        .disabled(session.activeProfile == nil)

        Button("Add Spacer") {
            guard let profileID = session.activeProfile?.id else { return }
            session.addSpacer(to: profileID)
            panelController.refresh()
        }
        .disabled(session.activeProfile == nil)

        if let profile = session.activeProfile, !profile.tiles.isEmpty {
            Menu("Remove Tile") {
                ForEach(profile.tiles) { tile in
                    Button(removeLabel(for: tile)) {
                        session.removeTile(id: tile.id, from: profile.id)
                        panelController.refresh()
                    }
                }
            }
        }

        Divider()

        Button("Edit Library…") {
            NSApp.activate()
            openWindow(id: EditorWindow.id)
        }

        Button("Quit OpenDock") {
            NSApp.terminate(nil)
        }

        if let lastError = session.lastError {
            Divider()
            Text(lastError)
                .foregroundStyle(.secondary)
        }
    }

    private func removeLabel(for tile: Tile) -> String {
        switch tile.kind {
        case .spacer:
            "Spacer"
        case .link, .path:
            tile.title.isEmpty ? "Untitled tile" : tile.title
        }
    }
}
