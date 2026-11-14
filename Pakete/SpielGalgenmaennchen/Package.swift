// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielGalgenmaennchen",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielGalgenmaennchen", targets: ["SpielGalgenmaennchen"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../../Test/DesignBilder"),
    ],
    targets: [
        .target(name: "SpielGalgenmaennchen", dependencies: [
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ], swiftSettings: [.enableUpcomingFeature("InferIsolatedConformances"), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
        .testTarget(name: "SpielGalgenmaennchenTests", dependencies: ["SpielGalgenmaennchen", .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "DesignBilder", package: "DesignBilder")]),
    ],
    swiftLanguageModes: [.v6]
)
