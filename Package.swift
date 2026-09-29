// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-6068",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 6068",
            targets: ["RFC 6068"]
        ),
        .library(
            name: "RFC 6068 Foundation Integration",
            targets: ["RFC 6068 Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-ietf/swift-rfc-3986.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5322.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 6068",
            dependencies: [
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
        .target(
            name: "RFC 6068 Foundation Integration",
            dependencies: [
                .target(name: "RFC 6068"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "RFC 5322 Foundation Integration", package: "swift-rfc-5322"),
            ]
        ),
        .testTarget(
            name: "RFC 6068 Foundation Integration Tests",
            dependencies: [
                .target(name: "RFC 6068"),
                .target(name: "RFC 6068 Foundation Integration"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
        .testTarget(
            name: "RFC 6068 Tests",
            dependencies: [
                .target(name: "RFC 6068"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
