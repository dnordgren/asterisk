// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "asterisk",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "AsteriskCore",
            targets: ["AsteriskCore"]
        ),
        .executable(
            name: "asterisk-cli",
            targets: ["AsteriskCLI"]
        ),
    ],
    targets: [
        .target(
            name: "AsteriskCore"
        ),
        .executableTarget(
            name: "AsteriskCLI",
            dependencies: ["AsteriskCore"]
        ),
        .testTarget(
            name: "AsteriskCoreTests",
            dependencies: ["AsteriskCore"]
        ),
    ]
)
