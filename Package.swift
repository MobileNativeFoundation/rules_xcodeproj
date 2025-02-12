// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "rules_xcodeproj",
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-build.git", branch: "main")
    ]
)
