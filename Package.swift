// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "home-control-adapter-sungrow-inverter",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "../home-control-kit"),
        .package(url: "https://github.com/f23a/home-control-client.git", from: "1.1.1"),
        .package(url: "https://github.com/cpageler93/SungrowKit.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "home-control-adapter-sungrow-inverter",
            dependencies: [
                .product(name: "HomeControlClient", package: "home-control-client"),
                .product(name: "SungrowKit", package: "SungrowKit"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)

