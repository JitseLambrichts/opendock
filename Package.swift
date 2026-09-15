// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OpenDock",
    platforms: [
        // App UI (follow-up) requires macOS 14+. Linux has no SPM platform
        // identifier here; OpenDockCore is Foundation-only so `swift test`
        // runs on Linux CI with the same tools version.
        .macOS(.v14),
    ],
    products: [
        .library(name: "OpenDockCore", targets: ["OpenDockCore"]),
    ],
    targets: [
        .target(name: "OpenDockCore"),
        .testTarget(
            name: "OpenDockCoreTests",
            dependencies: ["OpenDockCore"]
        ),
    ]
)
