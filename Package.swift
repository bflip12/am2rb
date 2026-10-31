// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "CrateMate",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "CrateMateCore"),
        .executableTarget(name: "CrateMate", dependencies: ["CrateMateCore"]),
        .testTarget(name: "CrateMateCoreTests", dependencies: ["CrateMateCore"]),
    ]
)
