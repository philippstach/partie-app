// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielWortpfeil",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielWortpfeil", targets: ["SpielWortpfeil"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../../Test/DesignBilder"),
    ],
    targets: [
        .target(name: "SpielWortpfeil", dependencies: [
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ], swiftSettings: [.enableUpcomingFeature("InferIsolatedConformances"), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
        .testTarget(name: "SpielWortpfeilTests", dependencies: ["SpielWortpfeil"]),
        .testTarget(name: "WortpfeilKlarTests", dependencies: ["SpielWortpfeil", .product(name: "KlarGlas", package: "Baukasten"), .product(name: "DesignBilder", package: "DesignBilder")]),
    ],
    swiftLanguageModes: [.v6]
)
