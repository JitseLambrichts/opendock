import Foundation

/// A named collection of dock tiles, typically one per OSS project.
public struct Profile: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var tiles: [Tile]

    public init(id: UUID = UUID(), name: String, tiles: [Tile] = []) {
        self.id = id
        self.name = name
        self.tiles = tiles
    }
}
