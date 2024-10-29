// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Calcal-backend",
    platforms: [ .macOS(.v12) ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.3.0")
    ],
    targets: [
        .executableTarget(name: "Calcal-backend", dependencies: [.product(name: "Hummingbird", package: "hummingbird")])
    ]
)
