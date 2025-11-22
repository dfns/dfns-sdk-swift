// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

// later change swift-tools-version to 6.2

import PackageDescription

let package = Package(
    name: "DfnsSdk",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v15),
		.watchOS(.v6),
		.tvOS(.v13)
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
