import AppKit
import SwiftUI

@main
struct OpenDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session: LibrarySession
    @State private var panelController: DockPanelController

    init() {
        let session = LibrarySession.live()
        _session = State(initialValue: session)
        _panelController = State(initialValue: DockPanelController(session: session))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(session: session, panelController: panelController)
        } label: {
            MenuBarLabel(session: session, panelController: panelController)
        }
        .menuBarExtraStyle(.menu)

        Window("Library", id: EditorWindow.id) {
            EditorView(session: session)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 620, height: 420)
    }
}

private struct MenuBarLabel: View {
    @Environment(\.openWindow) private var openWindow
    var session: LibrarySession
    var panelController: DockPanelController

    var body: some View {
        Label("OpenDock", systemImage: "dock.rectangle")
            .onAppear {
                panelController.show()
                if ProcessInfo.processInfo.environment["OPENDOCK_OPEN_EDITOR"] == "1" {
                    NSApp.activate()
                    openWindow(id: EditorWindow.id)
                }
            }
            .onChange(of: session.library) { _, _ in
                panelController.refresh()
            }
    }
}

enum EditorWindow {
    static let id = "library-editor"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
