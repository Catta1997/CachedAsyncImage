// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription

let package = Package(
    name: "CachedAsyncImage",
    platforms: [
        // Add support for all platforms starting from a specific version.
        .macOS(.v11)
    ],
    products: [
        .library(name: "CachedAsyncImage", targets: ["CachedAsyncImage"])
    ],
    targets: [
        .target(name: "CachedAsyncImage"),
        .testTarget(name: "CachedAsyncImageTests", dependencies: ["CachedAsyncImage"])
    ]
)
