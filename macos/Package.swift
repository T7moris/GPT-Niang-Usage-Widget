// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GPTNiangMac",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "GPTNiangMac", targets: ["GPTNiangMac"])],
    targets: [
        .target(name: "GPTNiangCore"),
        .executableTarget(name: "GPTNiangMac", dependencies: ["GPTNiangCore"]),
        .testTarget(name: "GPTNiangCoreTests", dependencies: ["GPTNiangCore"]),
        .testTarget(name: "GPTNiangMacTests", dependencies: ["GPTNiangMac"])
    ]
)
