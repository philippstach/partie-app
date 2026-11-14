// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielSolitaer",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSolitaer", targets: ["SpielSolitaer"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../../Test/DesignBilder"),
    ],
    targets: [
        .target(name: "SpielSolitaer", dependencies: [
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ], swiftSettings: [.enableUpcomingFeature("InferIsolatedConformances"), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
        .testTarget(name: "SpielSolitaerTests", dependencies: ["SpielSolitaer", .product(name: "DesignBilder", package: "DesignBilder")]),
    ],
    swiftLanguageModes: [.v5]
)
