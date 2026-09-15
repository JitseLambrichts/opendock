# OpenDock

Open-source project dock / launcher inspired by [Dockset](https://dockset.app/?v=0.2.2). Profiles pin **links**, **local paths**, and **spacers** for the OSS projects you work on.

This repository currently ships **OpenDockCore**, a Foundation-only Swift package that stores named profiles in local JSON. The SwiftUI macOS app is a follow-up on the same milestone.

See [PROJECT.MD](PROJECT.MD) for vision and v1 scope.

## Requirements

- Swift 5.9+
- macOS 14+ for the upcoming app; Linux is supported for `OpenDockCore` (`swift test`)

## Build and test

```sh
swift build
swift test
```

On macOS, the live library file is `~/Library/Application Support/OpenDock/library.json`. Tests inject a temporary file URL and do not use that path.

## License

MIT © 2026 Jitse Lambrichts
