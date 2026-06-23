// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotificationFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotificationFeature", targets: ["NotificationFeature"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(
            name: "NotificationFeature",
            dependencies: ["SharedModels"],
            path: "Sources/NotificationFeature"
        ),
        .testTarget(
            name: "NotificationFeatureTests",
            dependencies: ["NotificationFeature"],
            path: "Tests/NotificationFeatureTests"
        ),
    ]
)
