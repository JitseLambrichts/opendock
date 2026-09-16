import Foundation

#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Darwin)
import Darwin
#endif

/// Errors thrown by ``ProfileStore`` mutations.
public enum ProfileStoreError: Error, Equatable {
    case profileNotFound(UUID)
    case tileNotFound(UUID)
}

/// Owns a ``Library`` and persists it as JSON.
///
/// Plain `final class` (not `@Observable`) so the same type compiles and
/// tests on Linux. Callers can observe via ``onChange``.
public final class ProfileStore {
    public static let currentSchemaVersion = 1

    /// Default on-disk location: Application Support/`OpenDock`/`library.json`.
    public static var defaultLibraryURL: URL {
        let fm = FileManager.default
        let appSupport: URL
        if let url = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            appSupport = url
        } else {
            appSupport = fm.homeDirectoryForCurrentUser
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
        }
        return appSupport
            .appendingPathComponent("OpenDock", isDirectory: true)
            .appendingPathComponent("library.json", isDirectory: false)
    }

    public private(set) var library: Library
    public let fileURL: URL

    /// Invoked after a successful persist. Optional so tests can stay callback-free.
    public var onChange: ((Library) -> Void)?

    public convenience init() throws {
        try self.init(fileURL: Self.defaultLibraryURL)
    }

    /// Loads `fileURL`, or seeds a sample library and writes it when the file is missing.
    public init(fileURL: URL) throws {
        self.fileURL = fileURL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            self.library = try Self.makeDecoder().decode(Library.self, from: data)
        } else {
            self.library = Self.makeSeedLibrary()
            try Self.atomicWrite(Self.encode(self.library), to: fileURL)
        }
    }

    public var activeProfile: Profile? {
        library.activeProfile
    }

    public func setActive(profileID: UUID) throws {
        guard library.profiles.contains(where: { $0.id == profileID }) else {
            throw ProfileStoreError.profileNotFound(profileID)
        }
        library.activeProfileID = profileID
        try persist()
    }

    public func addProfile(_ profile: Profile) throws {
        library.profiles.append(profile)
        if library.activeProfileID == nil {
            library.activeProfileID = profile.id
        }
        try persist()
    }

    public func removeProfile(id: UUID) throws {
        guard library.profiles.contains(where: { $0.id == id }) else {
            throw ProfileStoreError.profileNotFound(id)
        }
        library.profiles.removeAll { $0.id == id }
        if library.activeProfileID == id {
            library.activeProfileID = library.profiles.first?.id
        }
        try persist()
    }

    public func addTile(_ tile: Tile, to profileID: UUID) throws {
        guard let index = library.profiles.firstIndex(where: { $0.id == profileID }) else {
            throw ProfileStoreError.profileNotFound(profileID)
        }
        library.profiles[index].tiles.append(tile)
        try persist()
    }

    public func removeTile(id: UUID, from profileID: UUID) throws {
        guard let profileIndex = library.profiles.firstIndex(where: { $0.id == profileID }) else {
            throw ProfileStoreError.profileNotFound(profileID)
        }
        guard library.profiles[profileIndex].tiles.contains(where: { $0.id == id }) else {
            throw ProfileStoreError.tileNotFound(id)
        }
        library.profiles[profileIndex].tiles.removeAll { $0.id == id }
        try persist()
    }

    public func renameProfile(id: UUID, to name: String) throws {
        guard let index = library.profiles.firstIndex(where: { $0.id == id }) else {
            throw ProfileStoreError.profileNotFound(id)
        }
        library.profiles[index].name = name
        try persist()
    }

    // MARK: - Persistence

    private func persist() throws {
        try Self.atomicWrite(Self.encode(library), to: fileURL)
        onChange?(library)
    }

    /// Write to a temp file in the same directory, then replace the destination.
    static func atomicWrite(_ data: Data, to fileURL: URL) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let tempURL = directory.appendingPathComponent(
            ".\(fileURL.lastPathComponent).\(UUID().uuidString).tmp"
        )
        try data.write(to: tempURL, options: [])

        do {
            try posixReplace(from: tempURL, to: fileURL)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
    }

    /// `rename(2)` in the same directory atomically replaces an existing file.
    private static func posixReplace(from source: URL, to destination: URL) throws {
        let status = source.path.withCString { src in
            destination.path.withCString { dst in
                rename(src, dst)
            }
        }
        if status != 0 {
            throw NSError(
                domain: NSPOSIXErrorDomain,
                code: Int(errno),
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Failed to replace \(destination.path) with \(source.path)"
                ]
            )
        }
    }

    static func encode(_ library: Library) throws -> Data {
        try makeEncoder().encode(library)
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func makeSeedLibrary() -> Library {
        let tiles = [
            Tile(
                title: "GitHub",
                kind: .link(URL(string: "https://github.com/JitseLambrichts/opendock")!)
            ),
            Tile(
                title: "Project notes",
                kind: .link(URL(string: "https://github.com/JitseLambrichts/opendock/blob/main/PROJECT.MD")!)
            ),
            Tile(title: "", kind: .spacer),
            Tile(title: "Checkout", kind: .path("~/Projects/opendock")),
        ]
        let profile = Profile(name: "OpenDock", tiles: tiles)
        return Library(
            schemaVersion: currentSchemaVersion,
            profiles: [profile],
            activeProfileID: profile.id
        )
    }
}
