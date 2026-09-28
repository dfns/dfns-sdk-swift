// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DfnsSdk",
    // Passkeys require iOS 15+ (see docs: practical floor iOS 16). macOS 12 is declared so the
    // platform-independent logic (Utils, DfnsApi models) builds and unit-tests on a Mac host via
    // `swift test`; the passkey/UIKit code is guarded for non-UIKit platforms.
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DfnsSdk",
            targets: ["DfnsSdk"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DfnsSdk"),
        .testTarget(
            name: "DfnsSdkTests",
            dependencies: ["DfnsSdk"]),
    ]
)
