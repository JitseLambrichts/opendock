import OpenDockCore
import SwiftUI

struct DockPanelView: View {
    let profile: Profile?
    let onOpen: (Tile) -> Void
    var onAddSpacer: (() -> Void)?
    var onRemoveLastTile: (() -> Void)?
    var onCycleProfile: (() -> Void)?

    var body: some View {
        Group {
            if let profile, !profile.tiles.isEmpty {
                HStack(alignment: .center, spacing: 4) {
                    profileButton
                    ForEach(profile.tiles) { tile in
                        tileView(tile)
                    }
                    controlButtons
                }
            } else {
                HStack(spacing: 10) {
                    profileButton
                    Text(profile == nil
                         ? "No profile yet. Add one from the menu bar."
                         : "No tiles yet. Choose Edit Library to add some.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    controlButtons
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.28), radius: 14, y: 6)
        }
        .padding(8)
    }

    @ViewBuilder
    private var profileButton: some View {
        if let onCycleProfile {
            Button(action: onCycleProfile) {
                Text(profile?.name ?? "OpenDock")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: 72)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Next profile")
        }
    }

    @ViewBuilder
    private var controlButtons: some View {
        if onAddSpacer != nil || onRemoveLastTile != nil {
            HStack(spacing: 2) {
                if let onAddSpacer {
                    Button(action: onAddSpacer) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 22, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Add spacer")
                }
                if let onRemoveLastTile {
                    Button(action: onRemoveLastTile) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 22, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Remove last tile")
                    .disabled(profile?.tiles.isEmpty ?? true)
                }
            }
        }
    }

    @ViewBuilder
    private func tileView(_ tile: Tile) -> some View {
        switch tile.kind {
        case .spacer:
            Color.clear
                .frame(width: 18, height: 52)
                .accessibilityHidden(true)
        case .link, .path:
            Button {
                onOpen(tile)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: iconName(for: tile.kind))
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 40, height: 30)
                    Text(tile.title)
                        .font(.caption2)
                        .lineLimit(1)
                        .frame(maxWidth: 68)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(helpText(for: tile))
        }
    }

    private func iconName(for kind: TileKind) -> String {
        switch kind {
        case .link:
            "link"
        case .path:
            "folder"
        case .spacer:
            "minus"
        }
    }

    private func helpText(for tile: Tile) -> String {
        switch tile.kind {
        case .link(let url):
            url.absoluteString
        case .path(let path):
            path
        case .spacer:
            "Spacer"
        }
    }
}
