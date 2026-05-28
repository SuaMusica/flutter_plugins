// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "smplayer",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "smplayer", targets: ["smplayer"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/AFNetworking/AFNetworking.git", from: "4.0.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.17.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.14.0"),
    ],
    targets: [
        .target(
            name: "smplayer",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AFNetworking", package: "AFNetworking"),
                .product(name: "SDWebImage", package: "SDWebImage"),
                .product(name: "SDWebImageWebPCoder", package: "SDWebImageWebPCoder"),
            ],
            resources: [
                .process("sm_cd_cover.png"),
            ],
            publicHeadersPath: "include/smplayer",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("MediaPlayer"),
                .linkedFramework("UIKit"),
            ]
        ),
    ]
)
