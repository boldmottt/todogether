// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WidgetFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "WidgetFeature", targets: ["WidgetFeature"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(
            name: "WidgetFeature",
            dependencies: ["SharedModels"],
            path: "Sources/WidgetFeature"
        ),
        .testTarget(
            name: "WidgetFeatureTests",
            dependencies: ["WidgetFeature"],
            path: "Tests/WidgetFeatureTests"
        ),
    ]
)
