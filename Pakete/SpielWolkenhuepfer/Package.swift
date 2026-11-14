// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Wolkenhüpfer: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielWolkenhuepfer",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielWolkenhuepfer", targets: ["SpielWolkenhuepfer"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../ArcadeKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "WolkenhuepferKern", dependencies: [.product(name: "ArcadeKern", package: "ArcadeKern")]),
        .target(name: "SpielWolkenhuepfer", dependencies: ["WolkenhuepferKern", .product(name: "ArcadeKern", package: "ArcadeKern"), .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "WolkenhuepferKernTests", dependencies: ["WolkenhuepferKern"]),
    ],
    swiftLanguageModes: [.v5]
)
