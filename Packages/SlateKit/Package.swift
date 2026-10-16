// swift-tools-version: 6.2
import PackageDescription

let shared: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]
let mainActor: [SwiftSetting] = shared + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "SlateKit",
    platforms: [.macOS("26.4")],
    products: [
        .library(name: "SlateComposition", targets: ["SlateComposition"]),
        .executable(name: "slate", targets: ["SlateCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.9.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "1.10.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
    ],
    targets: [
        .target(name: "SlateDomain", swiftSettings: shared),
        .target(
            name: "SlateData",
            dependencies: [
                "SlateDomain",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            swiftSettings: shared
        ),
        .target(name: "SlateMocks", dependencies: ["SlateDomain"], swiftSettings: shared),
        .target(name: "SlateUI", swiftSettings: mainActor),
        .target(name: "SlateEditor", swiftSettings: mainActor),
        .target(
            name: "SlatePresentation",
            dependencies: [
                "SlateDomain", "SlateUI", "SlateEditor", "SlateMocks",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            swiftSettings: mainActor
        ),
        .target(
            name: "SlateComposition",
            dependencies: ["SlateDomain", "SlateData", "SlateMocks", "SlatePresentation"],
            swiftSettings: mainActor
        ),
        .target(name: "SlateTestSupport", dependencies: ["SlateDomain"], swiftSettings: shared),
        .executableTarget(
            name: "SlateCLI",
            dependencies: [
                "SlateDomain", "SlateData",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: shared
        ),
        .testTarget(name: "SlateDomainTests", dependencies: ["SlateDomain", "SlateTestSupport"], swiftSettings: shared),
        .testTarget(name: "SlateDataTests", dependencies: ["SlateData", "SlateMocks", "SlateTestSupport"], swiftSettings: shared),
        .testTarget(name: "SlateEditorTests", dependencies: ["SlateEditor"], swiftSettings: mainActor),
        .testTarget(name: "SlateUITests", dependencies: ["SlateUI"], swiftSettings: mainActor),
        .testTarget(name: "SlatePresentationTests", dependencies: ["SlatePresentation", "SlateMocks", "SlateTestSupport"], swiftSettings: mainActor),
    ]
)
