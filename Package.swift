// swift-tools-version: 6.2

import PackageDescription

extension String {
    static let rfc6068: Self = "RFC 6068"
}

extension Target.Dependency {
    static var rfc6068: Self { .target(name: .rfc6068) }
}

extension Target.Dependency {
    static var incits41986: Self { .product(name: "ASCII Serializer Primitives", package: "swift-ascii-serializer-primitives") }
    static var rfc3986: Self { .product(name: "RFC 3986", package: "swift-rfc-3986") }
    static var rfc5322: Self { .product(name: "RFC 5322", package: "swift-rfc-5322") }
}

let package = Package(
    name: "swift-rfc-6068",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "RFC 6068", targets: ["RFC 6068"]),
        .library(name: .rfc6068.foundation, targets: [.rfc6068.foundation])
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-ascii-serializer-primitives"),
        .package(path: "../swift-rfc-3986"),
        .package(path: "../swift-rfc-5322"),
        .package(path: "../../swift-primitives/swift-parser-primitives")
    ],
    targets: [
        .target(
            name: "RFC 6068",
            dependencies: [
                .incits41986,
                .rfc3986,
                .rfc5322,
                .product(name: "Parser Primitives", package: "swift-parser-primitives")
            ]
        ),
        .target(
            name: .rfc6068.foundation,
            dependencies: [
                .rfc6068
            ]
        ),
        .testTarget(
            name: "RFC 6068 Foundation Tests",
            dependencies: [
                "RFC 6068",
            ]
        ),
        .testTarget(
            name: "RFC 6068 Tests",
            dependencies: [
                "RFC 6068",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
