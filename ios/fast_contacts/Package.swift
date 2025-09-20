// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fast_contacts",
    platforms: [
        .iOS("11.0")
    ],
    products: [
        .library(name: "fast-contacts", targets: ["fast_contacts"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "fast_contacts",
            dependencies: ["FastContactsSwift"],
            path: "Sources/FastContactsPlugin",
            publicHeadersPath: "include"
        ),
        .target(
            name: "FastContactsSwift",
            dependencies: [],
            path: "Sources/FastContactsSwift"
        )
    ]
)