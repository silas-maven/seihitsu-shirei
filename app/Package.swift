// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Seihitsu",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Seihitsu",
            path: "Sources/Seihitsu"
        )
    ]
)
