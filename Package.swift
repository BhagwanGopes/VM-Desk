// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VMDesk",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "VMDesk", targets: ["VMDesk"])
    ],
    targets: [
        .executableTarget(
            name: "VMDesk",
            path: "Sources/VMDesk",
            resources: [
                .process("Display/Shaders.metal")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VMDeskTests",
            dependencies: ["VMDesk"],
            path: "Tests/VMDeskTests"
        )
    ]
)
