// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TodoFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TodoFeature", targets: ["TodoFeature"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../SpaceFeature"),
        .package(path: "../NotificationFeature"),
    ],
    targets: [
        .target(
            name: "TodoFeature",
            dependencies: ["SharedModels", "SpaceFeature", "NotificationFeature"],
            path: "Sources/TodoFeature"
        ),
        .testTarget(
            name: "TodoFeatureTests",
            dependencies: ["TodoFeature"],
            path: "Tests/TodoFeatureTests"
        ),
    ]
)
