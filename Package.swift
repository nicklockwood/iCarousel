// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iCarousel",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_10),
    ],
    products: [
        .library(
            name: "iCarousel",
            targets: ["iCarousel"]),
    ],
    targets: [
        .target(
            name: "iCarousel",
            path: "iCarousel",
            exclude: ["iCarousel/Info.plist"]),
        .testTarget(
            name: "iCarouselTests",
            dependencies: ["iCarousel"]),
    ]
)
