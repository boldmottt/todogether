// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TemplateFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TemplateFeature", targets: ["TemplateFeature"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../TodoFeature"),
    ],
    targets: [
        .target(
            name: "TemplateFeature",
            dependencies: ["SharedModels", "TodoFeature"],
            path: "Sources/TemplateFeature"
        ),
        .testTarget(
            name: "TemplateFeatureTests",
            dependencies: ["TemplateFeature"],
            path: "Tests/TemplateFeatureTests"
        ),
    ]
)
