import AppKit
import Foundation
import OpenDockCore

enum TileOpener {
    @MainActor
    static func open(_ tile: Tile) {
        switch tile.kind {
        case .link(let url):
            NSWorkspace.shared.open(url)
        case .path(let path):
            revealOrOpen(path: path)
        case .spacer:
            break
        }
    }

    @MainActor
    private static func revealOrOpen(path: String) {
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        if FileManager.default.fileExists(atPath: expanded) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return
        }
        let parent = url.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: parent.path) {
            NSWorkspace.shared.activateFileViewerSelecting([parent])
            return
        }
        NSWorkspace.shared.open(url)
    }
}
