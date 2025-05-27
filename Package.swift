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
	@@ -21,10 +21,6 @@ let package = Package(
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
