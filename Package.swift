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
            .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.4")

    ],
    targets: [
        .binaryTarget(
            name: "WebRTCiOSSDK",
            //dependencies: ["Starscream"],
            path: "WebRTCiOSSDK.xcframework"
        ),
        .binaryTarget(
            name: "WebRTC",
            path: "WebRTCiOSSDK/WebRTC.xcframework"
        )
    ]
)
