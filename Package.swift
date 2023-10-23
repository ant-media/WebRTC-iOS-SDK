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
            targets: ["WebRTCiOSSDK", "WebRTC"]
        ),
    ],
    dependencies: [
            .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.6")

    ],
    targets: [
        .target(
            name: "WebRTCiOSSDK",
            dependencies: ["Starscream"],
            path: "WebRTCiOSSDK"
        ),
        .binaryTarget(
            name: "WebRTC",
            path: "WebRTC.xcframework"
        )
    ]
)
