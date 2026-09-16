import Foundation

/// A pinned item in a project dock profile.
public enum TileKind: Equatable {
    /// Open this URL (repo, docs, CI dashboard, chat, …).
    case link(URL)
    /// Reveal this local file or folder path.
    case path(String)
    /// Visual gap between tiles.
    case spacer
}

extension TileKind: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case url
        case path
    }

    private enum KindDiscriminator: String, Codable {
        case link
        case path
        case spacer
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .link(let url):
            try container.encode(KindDiscriminator.link, forKey: .type)
            try container.encode(url, forKey: .url)
        case .path(let path):
            try container.encode(KindDiscriminator.path, forKey: .type)
            try container.encode(path, forKey: .path)
        case .spacer:
            try container.encode(KindDiscriminator.spacer, forKey: .type)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(KindDiscriminator.self, forKey: .type)
        switch kind {
        case .link:
            self = .link(try container.decode(URL.self, forKey: .url))
        case .path:
            self = .path(try container.decode(String.self, forKey: .path))
        case .spacer:
            self = .spacer
        }
    }
}
