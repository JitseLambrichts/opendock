import Foundation

/// On-disk document owned by ``ProfileStore``.
public struct Library: Codable, Equatable {
    /// Bump when the JSON shape changes incompatibly. Starts at `1`.
    public var schemaVersion: Int
    public var profiles: [Profile]
    public var activeProfileID: UUID?

    public init(
        schemaVersion: Int = 1,
        profiles: [Profile] = [],
        activeProfileID: UUID? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.profiles = profiles
        self.activeProfileID = activeProfileID
    }

    public var activeProfile: Profile? {
        guard let activeProfileID else { return nil }
        return profiles.first(where: { $0.id == activeProfileID })
    }
}
