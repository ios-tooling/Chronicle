// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Chronicle",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Chronicle",
            targets: ["Chronicle"]
        )
    ],
    targets: [
        .target(
            name: "Chronicle",
            path: "Sources/Chronicle"
        ),
        .testTarget(
            name: "ChronicleTests",
            dependencies: ["Chronicle"],
            path: "Tests/ChronicleTests"
        )
    ]
)
