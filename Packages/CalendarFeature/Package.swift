// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CalendarFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CalendarFeature", targets: ["CalendarFeature"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../TodoFeature"),
    ],
    targets: [
        .target(
            name: "CalendarFeature",
            dependencies: ["SharedModels", "TodoFeature"],
            path: "Sources/CalendarFeature"
        ),
        .testTarget(
            name: "CalendarFeatureTests",
            dependencies: ["CalendarFeature"],
            path: "Tests/CalendarFeatureTests"
        ),
    ]
)
