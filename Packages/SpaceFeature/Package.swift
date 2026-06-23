// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpaceFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SpaceFeature", targets: ["SpaceFeature"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(
            name: "SpaceFeature",
            dependencies: ["SharedModels"],
            path: "Sources/SpaceFeature"
        ),
        .testTarget(
            name: "SpaceFeatureTests",
            dependencies: ["SpaceFeature"],
            path: "Tests/SpaceFeatureTests"
        ),
    ]
)
