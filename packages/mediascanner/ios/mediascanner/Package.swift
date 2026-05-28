// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mediascanner",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "mediascanner", targets: ["mediascanner"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "mediascanner",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            publicHeadersPath: "include/mediascanner"
        ),
    ]
)
