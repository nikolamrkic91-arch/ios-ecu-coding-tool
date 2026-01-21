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
        .executable(
            name: "ECUCodingApp",
            targets: ["ECUCodingApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ECUCodingCore",
            path: "Sources/ECUCodingCore"
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
