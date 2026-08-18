// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CaptureProof",
    platforms: [.macOS(.v14)], // SCScreenshotManager requires macOS 14+
    targets: [
        .executableTarget(name: "CaptureProof", path: "Sources/CaptureProof")
    ]
)
