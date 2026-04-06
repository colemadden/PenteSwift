// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PenteCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "PenteCore", targets: ["PenteCore"]),
    ],
    targets: [
        .target(name: "PenteCore"),
        .testTarget(name: "PenteCoreTests", dependencies: ["PenteCore"]),
    ]
)
