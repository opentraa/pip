// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "native_plugin",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "native-plugin", targets: ["native_plugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "native_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/native_plugin",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/native_plugin")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVKit"),
                .linkedFramework("UIKit")
            ]
        )
    ]
)
