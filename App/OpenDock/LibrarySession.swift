import Foundation
import Observation
import OpenDockCore

/// SwiftUI-facing owner of ``ProfileStore``. Mutations persist to the core's default
/// Application Support file (`OpenDock/library.json`) unless a custom store is injected.
@MainActor
@Observable
final class LibrarySession {
    private let store: ProfileStore

    private(set) var library: Library
    var lastError: String?

    init(store: ProfileStore) {
        self.store = store
        self.library = store.library
    }

    static func live() -> LibrarySession {
        do {
            return LibrarySession(store: try ProfileStore())
        } catch {
            let fallback = FileManager.default.temporaryDirectory
                .appendingPathComponent("OpenDock-fallback-\(UUID().uuidString)", isDirectory: true)
                .appendingPathComponent("library.json")
            do {
                let session = LibrarySession(store: try ProfileStore(fileURL: fallback))
                session.lastError = error.localizedDescription
                return session
            } catch {
                preconditionFailure("OpenDock could not create a profile library: \(error)")
            }
        }
    }

    var profiles: [Profile] { library.profiles }
    var activeProfile: Profile? { library.activeProfile }

    func setActive(_ id: UUID) {
        perform { try store.setActive(profileID: id) }
    }

    func addProfile(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let profile = Profile(name: trimmed)
        perform {
            try store.addProfile(profile)
            try store.setActive(profileID: profile.id)
        }
    }

    func removeProfile(id: UUID) {
        perform { try store.removeProfile(id: id) }
    }

    func renameProfile(id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        perform { try store.renameProfile(id: id, to: trimmed) }
    }

    func addTile(_ tile: Tile, to profileID: UUID) {
        perform { try store.addTile(tile, to: profileID) }
    }

    func addLink(title: String, urlString: String, to profileID: UUID) {
        guard let url = Self.parseURL(urlString) else {
            lastError = "Enter a valid URL."
            return
        }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        addTile(
            Tile(title: name.isEmpty ? (url.host ?? "Link") : name, kind: .link(url)),
            to: profileID
        )
    }

    func addPath(title: String, path: String, to profileID: UUID) {
        let expandedHint = (path as NSString).expandingTildeInPath
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else {
            lastError = "Enter a file or folder path."
            return
        }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        addTile(
            Tile(
                title: name.isEmpty ? URL(fileURLWithPath: expandedHint).lastPathComponent : name,
                kind: .path(trimmedPath)
            ),
            to: profileID
        )
    }

    func addSpacer(to profileID: UUID) {
        addTile(Tile(title: "", kind: .spacer), to: profileID)
    }

    func removeTile(id: UUID, from profileID: UUID) {
        perform { try store.removeTile(id: id, from: profileID) }
    }

    static func parseURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
            library = store.library
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
