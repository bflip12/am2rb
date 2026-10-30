// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "am2rb",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "Am2rbCore"),
        .executableTarget(name: "am2rb", dependencies: ["Am2rbCore"]),
        .testTarget(name: "Am2rbCoreTests", dependencies: ["Am2rbCore"]),
    ]
)
