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
    targets: [
        .binaryTarget(
            name: "WebRTCiOSSDK",
            path: "WebRTCiOSSDK.xcframework"
        )
    ]
)
