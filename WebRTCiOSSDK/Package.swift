import PackageDescription

let package = Package(
    name: "WebRTCiOSSDK",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(
            name: "WebRTCiOSSDK",
            targets: ["WebRTCiOSSDK"]
        ),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "WebRTCiOSSDK",
            url: "../WebRTCiOSSDK.xcframework",
        ),
    ]
)
