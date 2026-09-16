import AppKit
import OpenDockCore
import SwiftUI

@MainActor
final class DockPanelController {
    private let session: LibrarySession
    private var panel: DockPanel?
    private var hostingView: FirstMouseHostingView<DockPanelView>?

    init(session: LibrarySession) {
        self.session = session
    }

    func show() {
        if panel == nil {
            makePanel()
        }
        refresh()
        panel?.orderFrontRegardless()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            writeSnapshotIfRequested()
        }
    }

    func writeSnapshot(to url: URL) {
        let size = Self.size(for: session.activeProfile)
        let renderer = ImageRenderer(
            content: DockPanelView(
                profile: session.activeProfile,
                onOpen: { _ in },
                onAddSpacer: {},
                onRemoveLastTile: {},
                onCycleProfile: {}
            )
            .frame(width: size.width, height: size.height)
        )
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            return
        }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? png.write(to: url)
    }

    private func writeSnapshotIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["OPENDOCK_SNAPSHOT"], !path.isEmpty else {
            return
        }
        writeSnapshot(to: URL(fileURLWithPath: path))
    }

    func refresh() {
        guard let hostingView, let panel else { return }
        hostingView.rootView = DockPanelView(
            profile: session.activeProfile,
            onOpen: TileOpener.open,
            onAddSpacer: addSpacer,
            onRemoveLastTile: removeLastTile,
            onCycleProfile: cycleProfile
        )
        let size = Self.size(for: session.activeProfile)
        hostingView.frame = NSRect(origin: .zero, size: size)
        position(panel, size: size)
    }

    private func makePanel() {
        let size = Self.size(for: session.activeProfile)
        let panel = DockPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .utilityWindow
        panel.acceptsMouseMovedEvents = true

        let hosting = FirstMouseHostingView(
            rootView: DockPanelView(
                profile: session.activeProfile,
                onOpen: TileOpener.open,
                onAddSpacer: addSpacer,
                onRemoveLastTile: removeLastTile,
                onCycleProfile: cycleProfile
            )
        )
        hosting.frame = NSRect(origin: .zero, size: size)
        panel.contentView = hosting

        self.panel = panel
        self.hostingView = hosting
    }

    private func position(_ panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let x = visible.midX - size.width / 2
        let y = visible.minY + 16
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    static func size(for profile: Profile?) -> NSSize {
        let tiles = profile?.tiles ?? []
        guard !tiles.isEmpty else {
            return NSSize(width: 280, height: 88)
        }
        var width: CGFloat = 28
        for tile in tiles {
            switch tile.kind {
            case .spacer:
                width += 22
            case .link, .path:
                width += 80
            }
        }
        width += 56 + 80
        return NSSize(width: max(width, 160), height: 88)
    }

    private func addSpacer() {
        guard let id = session.activeProfile?.id else { return }
        session.addSpacer(to: id)
        refresh()
    }

    private func removeLastTile() {
        guard let profile = session.activeProfile, let tile = profile.tiles.last else { return }
        session.removeTile(id: tile.id, from: profile.id)
        refresh()
    }

    private func cycleProfile() {
        let profiles = session.profiles
        guard profiles.count >= 2,
              let current = session.library.activeProfileID,
              let index = profiles.firstIndex(where: { $0.id == current })
        else {
            return
        }
        let next = profiles[(index + 1) % profiles.count]
        session.setActive(next.id)
        refresh()
    }
}

final class DockPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
