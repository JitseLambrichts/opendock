import Foundation
import XCTest
@testable import OpenDockCore

final class OpenDockCoreTests: XCTestCase {
    private var scratchDirectory: URL!

    override func setUpWithError() throws {
        scratchDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenDockCoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: scratchDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let scratchDirectory {
            try? FileManager.default.removeItem(at: scratchDirectory)
        }
        scratchDirectory = nil
    }

    // MARK: - Codable

    func testTileKindAndLibraryRoundTrip() throws {
        let tiles = [
            Tile(title: "Repo", kind: .link(URL(string: "https://github.com/JitseLambrichts/opendock")!)),
            Tile(title: "Sources", kind: .path("/tmp/opendock")),
            Tile(title: "", kind: .spacer),
        ]
        let profile = Profile(name: "RoundTrip", tiles: tiles)
        let library = Library(
            schemaVersion: 1,
            profiles: [profile],
            activeProfileID: profile.id
        )

        let data = try ProfileStore.encode(library)
        let decoded = try ProfileStore.makeDecoder().decode(Library.self, from: data)

        XCTAssertEqual(decoded, library)
        XCTAssertEqual(decoded.profiles[0].tiles.map(\.kind), [
            .link(URL(string: "https://github.com/JitseLambrichts/opendock")!),
            .path("/tmp/opendock"),
            .spacer,
        ])
    }

    func testTileKindJSONUsesTypeDiscriminator() throws {
        let encoder = ProfileStore.makeEncoder()
        let linkData = try encoder.encode(TileKind.link(URL(string: "https://example.com")!))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: linkData) as? [String: Any])
        XCTAssertEqual(json["type"] as? String, "link")
        XCTAssertEqual(json["url"] as? String, "https://example.com")
    }

    // MARK: - Seed

    func testSeedsSampleLibraryWhenFileIsMissing() throws {
        let url = libraryURL()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        let store = try ProfileStore(fileURL: url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(store.library.schemaVersion, ProfileStore.currentSchemaVersion)
        XCTAssertEqual(store.library.profiles.count, 1)
        XCTAssertEqual(store.library.profiles[0].name, "OpenDock")
        XCTAssertEqual(store.library.activeProfileID, store.library.profiles[0].id)

        let kinds = store.library.profiles[0].tiles.map(\.kind)
        XCTAssertTrue(kinds.contains { if case .link = $0 { return true } else { return false } })
        XCTAssertTrue(kinds.contains { if case .path = $0 { return true } else { return false } })
        XCTAssertTrue(kinds.contains(.spacer))
    }

    // MARK: - Mutations

    func testSetActiveSwitchesProfile() throws {
        let store = try seededStore()
        let extra = Profile(name: "Other", tiles: [])
        try store.addProfile(extra)

        try store.setActive(profileID: extra.id)

        XCTAssertEqual(store.library.activeProfileID, extra.id)
        XCTAssertEqual(store.activeProfile?.name, "Other")
    }

    func testSetActiveUnknownProfileThrows() throws {
        let store = try seededStore()
        let missing = UUID()
        XCTAssertThrowsError(try store.setActive(profileID: missing)) { error in
            XCTAssertEqual(error as? ProfileStoreError, .profileNotFound(missing))
        }
    }

    func testAddAndRemoveProfile() throws {
        let store = try seededStore()
        let originalID = try XCTUnwrap(store.library.activeProfileID)
        let extra = Profile(name: "Docs", tiles: [])
        try store.addProfile(extra)

        XCTAssertEqual(store.library.profiles.map(\.name), ["OpenDock", "Docs"])

        try store.removeProfile(id: originalID)

        XCTAssertEqual(store.library.profiles.map(\.name), ["Docs"])
        XCTAssertEqual(store.library.activeProfileID, extra.id)

        try store.removeProfile(id: extra.id)
        XCTAssertTrue(store.library.profiles.isEmpty)
        XCTAssertNil(store.library.activeProfileID)
    }

    func testAddAndRemoveTile() throws {
        let store = try seededStore()
        let profileID = try XCTUnwrap(store.library.profiles.first?.id)
        let initialCount = try XCTUnwrap(store.library.profiles.first).tiles.count

        let tile = Tile(title: "CI", kind: .link(URL(string: "https://github.com/JitseLambrichts/opendock/actions")!))
        try store.addTile(tile, to: profileID)
        XCTAssertEqual(store.library.profiles[0].tiles.count, initialCount + 1)
        XCTAssertEqual(store.library.profiles[0].tiles.last?.id, tile.id)

        try store.removeTile(id: tile.id, from: profileID)
        XCTAssertEqual(store.library.profiles[0].tiles.count, initialCount)
        XCTAssertFalse(store.library.profiles[0].tiles.contains(where: { $0.id == tile.id }))
    }

    func testRenameProfile() throws {
        let store = try seededStore()
        let profileID = try XCTUnwrap(store.library.profiles.first?.id)
        try store.renameProfile(id: profileID, to: "OpenDock Core")
        XCTAssertEqual(store.library.profiles[0].name, "OpenDock Core")
    }

    func testRemoveUnknownProfileAndTileThrow() throws {
        let store = try seededStore()
        let missing = UUID()
        XCTAssertThrowsError(try store.removeProfile(id: missing)) { error in
            XCTAssertEqual(error as? ProfileStoreError, .profileNotFound(missing))
        }
        let profileID = try XCTUnwrap(store.library.profiles.first?.id)
        XCTAssertThrowsError(try store.removeTile(id: missing, from: profileID)) { error in
            XCTAssertEqual(error as? ProfileStoreError, .tileNotFound(missing))
        }
    }

    // MARK: - Atomic persist

    func testAtomicPersistReloadsMatchingLibrary() throws {
        let url = libraryURL()
        let store = try ProfileStore(fileURL: url)
        let extra = Profile(
            name: "Second",
            tiles: [Tile(title: "Home", kind: .path("/tmp"))]
        )
        try store.addProfile(extra)
        try store.setActive(profileID: extra.id)
        try store.renameProfile(id: extra.id, to: "Reloaded")
        try store.addTile(
            Tile(title: "Issues", kind: .link(URL(string: "https://github.com/JitseLambrichts/opendock/issues")!)),
            to: extra.id
        )

        let reloaded = try ProfileStore(fileURL: url)
        XCTAssertEqual(reloaded.library, store.library)
        XCTAssertEqual(reloaded.activeProfile?.name, "Reloaded")
        XCTAssertEqual(reloaded.activeProfile?.tiles.map(\.title), ["Home", "Issues"])
    }

    func testAtomicWriteReplacesExistingFile() throws {
        let url = libraryURL()
        try ProfileStore.atomicWrite(Data("stale".utf8), to: url)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "stale")

        let payload = Data("{\"ok\":true}".utf8)
        try ProfileStore.atomicWrite(payload, to: url)
        XCTAssertEqual(try Data(contentsOf: url), payload)
        let leftovers = try FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasSuffix(".tmp") }
        XCTAssertTrue(leftovers.isEmpty, "temp files should be replaced away, not left behind")
    }

    // MARK: - Helpers

    private func libraryURL() -> URL {
        scratchDirectory.appendingPathComponent("library.json")
    }

    private func seededStore() throws -> ProfileStore {
        try ProfileStore(fileURL: libraryURL())
    }
}
