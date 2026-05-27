// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "HEICtoJPEG",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HEICtoJPEGCore",
            targets: ["HEICtoJPEGCore"]
        ),
        .executable(
            name: "HEICtoJPEGApp",
            targets: ["HEICtoJPEGApp"]
        )
    ],
    targets: [
        .target(
            name: "HEICtoJPEGCore"
        ),
        .executableTarget(
            name: "HEICtoJPEGApp",
            dependencies: ["HEICtoJPEGCore"]
        ),
        .testTarget(
            name: "HEICtoJPEGCoreTests",
            dependencies: ["HEICtoJPEGCore"]
        )
    ]
)
