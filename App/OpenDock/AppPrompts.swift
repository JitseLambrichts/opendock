import AppKit

enum AppPrompts {
    @MainActor
    static func askText(
        title: String,
        message: String,
        placeholder: String,
        confirm: String = "Add"
    ) -> String? {
        let field = NSTextField(string: "")
        field.placeholderString = placeholder
        field.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        return runAlert(title: title, message: message, confirm: confirm, accessory: field).map {
            field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    @MainActor
    static func askTwoFields(
        title: String,
        message: String,
        firstPlaceholder: String,
        secondPlaceholder: String,
        confirm: String = "Add"
    ) -> (String, String)? {
        let first = NSTextField(string: "")
        first.placeholderString = firstPlaceholder
        let second = NSTextField(string: "")
        second.placeholderString = secondPlaceholder
        let stack = NSStackView(views: [first, second])
        stack.orientation = .vertical
        stack.spacing = 6
        stack.frame = NSRect(x: 0, y: 0, width: 280, height: 54)
        first.translatesAutoresizingMaskIntoConstraints = false
        second.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            first.widthAnchor.constraint(equalToConstant: 280),
            second.widthAnchor.constraint(equalToConstant: 280),
        ])
        guard runAlert(title: title, message: message, confirm: confirm, accessory: stack) != nil else {
            return nil
        }
        return (
            first.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            second.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    @MainActor
    static func confirm(title: String, message: String, confirm: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: confirm)
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()
        return alert.runModal() == .alertFirstButtonReturn
    }

    @MainActor
    static func choosePath() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.message = "Choose a file or folder to pin"
        panel.prompt = "Pin"
        NSApp.activate()
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    @MainActor
    private static func runAlert(
        title: String,
        message: String,
        confirm: String,
        accessory: NSView
    ) -> Void? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: confirm)
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = accessory
        alert.window.initialFirstResponder = accessory
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return ()
    }
}
