// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ios-ecu-coding-tool",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ECUCodingCore",
            targets: ["ECUCodingCore"]
        ),
        // This executable target lets you run a preview app via SwiftPM in Xcode.
        .executable(
            name: "ECUCodingApp",
            targets: ["ECUCodingApp"]
        )
    ],
    dependencies: [
        // Add external packages here (e.g., logging, diffing) as needed.
    ],
    targets: [
        .target(
            name: "ECUCodingCore",
            path: "Sources/ECUCodingCore",
            resources: [
                // Place definition bundles or fixtures here when ready.
                // .process("Resources")
            ]
        ),
        .executableTarget(
            name: "ECUCodingApp",
            dependencies: ["ECUCodingCore"],
            path: "Sources/ECUCodingApp"
        ),
        .testTarget(
            name: "ECUCodingCoreTests",
            dependencies: ["ECUCodingCore"],
            path: "Tests/ECUCodingCoreTests"
        )
    ]
)
