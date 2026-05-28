// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "equalizer",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "equalizer", targets: ["equalizer"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "equalizer",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            publicHeadersPath: "include/equalizer"
        ),
    ]
)
