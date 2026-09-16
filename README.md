# OpenDock

Open-source project dock / launcher inspired by [Dockset](https://dockset.app/?v=0.2.2). Profiles pin **links**, **local paths**, and **spacers** for the OSS projects you work on.

**OpenDockCore** is a Foundation-only Swift package (models + local JSON). The **macOS app** is a menu-bar extra with a floating project dock.

See [PROJECT.MD](PROJECT.MD) for vision and v1 scope.

## Requirements

- Swift 5.9+
- macOS 14+ for the app (Xcode 15+)
- Linux is supported for `OpenDockCore` (`swift test`)

## Core package

```sh
swift build
swift test
```

On macOS, the live library file is `~/Library/Application Support/OpenDock/library.json`. Tests inject a temporary file URL and do not use that path.

## macOS app

Open `App/OpenDock.xcodeproj` in Xcode, select the **OpenDock** scheme, and Run (⌘R). The app is an accessory / menu-bar extra, so it does not appear as a normal Dock app.

From the menu bar extra:

- Click a profile to make it active (checkmark)
- **Show Dock** to bring the floating panel forward
- Add or remove profiles and tiles (link, path, spacer), or **Edit Library…**
- **Quit OpenDock**

Click a link tile to open it in your browser. Click a path tile to reveal it in Finder.

Command line:

```sh
xcodebuild -project App/OpenDock.xcodeproj -scheme OpenDock -destination 'generic/platform=macOS' build
```

To regenerate the Xcode project after changing `App/project.yml`:

```sh
cd App && xcodegen generate
```

## License

MIT © 2026 Jitse Lambrichts
