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
         .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
   //      .package(url: "https://github.com/ant-media/WebRTC-iOS.git", .branch("main")),
         
    ],
    targets: [
        .binaryTarget(
            name: "WebRTCiOSSDK",
            path: "WebRTCiOSSDK.xcframework"
        ),
        .binaryTarget(
            name:"WebRTC",
            path:"WebRTC.xcframework"
        )
    ]
)
