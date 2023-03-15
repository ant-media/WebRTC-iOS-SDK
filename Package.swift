// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "AntMediaWebRTCSDK",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "WebRTCiOSSDK", targets: ["WebRTCiOSSDK"])
        ],
        dependencies: [ ],
        targets: [
            .target(
                name: "WebRTCiOSSDK",
                path: "WebRTCiOSSDK",
                sources: ["Classes"]),
    ]
)
