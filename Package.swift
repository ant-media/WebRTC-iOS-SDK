// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WebRTCiOSSDK",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "WebRTCiOSSDK",
            targets: ["WebRTCiOSSDK"]
        ),
    ],
    dependencies: [
         .Package(url: "https://github.com/daltoniam/Starscream.git", majorVersion: 4)
    ],
    targets: [
        .binaryTarget(
            name: "WebRTCiOSSDK",
            url: "WebRTCiOSSDK.xcframework",
        ),
    ]
)
