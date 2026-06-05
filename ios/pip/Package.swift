// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pip",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "pip", targets: ["pip"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "pip",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/pip",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/pip")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVKit"),
                .linkedFramework("UIKit")
            ]
        )
    ]
)
