// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreApp",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/Lastivky/PluginBuilder.git", branch: "main")
    ],
    targets: [
        .executableTarget(name: "CoreApp", dependencies: [
            .product(name: "PluginInterface", package: "PluginBuilder")
        ])
    ]
)
