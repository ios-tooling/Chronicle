// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Chronicle",
    platforms: [
        .iOS(.v14),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Chronicle",
            targets: ["Chronicle"]
        )
    ],
	 dependencies: [
		.package(url: "https://github.com/ios-tooling/TagAlong", from: "0.0.4"),
	 ],
    targets: [
        .target(
            name: "Chronicle",
				dependencies: ["TagAlong"],
            path: "Sources/Chronicle"
        ),
        .testTarget(
            name: "ChronicleTests",
            dependencies: ["Chronicle"],
            path: "Tests/ChronicleTests"
        )
    ]
)
