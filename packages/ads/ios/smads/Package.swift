// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "smads",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "smads", targets: ["smads"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios",
            from: "3.22.1"
        ),
    ],
    targets: [
        .target(
            name: "smads",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "GoogleInteractiveMediaAds", package: "GoogleInteractiveMediaAds"),
            ],
            resources: [
                .process("AdsViewController.xib"),
                .process("iPhone.storyboard"),
            ],
            publicHeadersPath: "include/smads"
        ),
    ]
)
