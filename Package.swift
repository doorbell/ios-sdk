// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Doorbell",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(
            name: "Doorbell",
            targets: ["Doorbell"]),
    ],
    dependencies: [
        // no dependencies
    ],
    targets: [
        .target(
            name: "Doorbell",
            dependencies: []),
        .testTarget(
            name: "DoorbellTests",
            dependencies: ["Doorbell"]),
    ]
)