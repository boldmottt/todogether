// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RecurringFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "RecurringFeature", targets: ["RecurringFeature"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../TodoFeature"),
    ],
    targets: [
        .target(
            name: "RecurringFeature",
            dependencies: ["SharedModels", "TodoFeature"],
            path: "Sources/RecurringFeature"
        ),
        .testTarget(
            name: "RecurringFeatureTests",
            dependencies: ["RecurringFeature"],
            path: "Tests/RecurringFeatureTests"
        ),
    ]
)
