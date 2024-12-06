// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "InfomaniakDeviceCheck",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(
            name: "InfomaniakDeviceCheck",
            targets: ["InfomaniakDeviceCheck"]
        ),
    ],
    targets: [
        .target(
            name: "InfomaniakDeviceCheck"
        ),
        .testTarget(
            name: "InfomaniakDeviceCheckTests",
            dependencies: ["InfomaniakDeviceCheck"]
        ),
    ]
)
