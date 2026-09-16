import Foundation

/// A single dock item belonging to a ``Profile``.
public struct Tile: Codable, Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var kind: TileKind

    public init(id: UUID = UUID(), title: String, kind: TileKind) {
        self.id = id
        self.title = title
        self.kind = kind
    }
}
