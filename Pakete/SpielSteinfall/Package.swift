// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Steinfall: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSteinfall",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSteinfall", targets: ["SpielSteinfall"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../ArcadeKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "SteinfallKern", dependencies: [.product(name: "ArcadeKern", package: "ArcadeKern")]),
        .target(name: "SpielSteinfall", dependencies: ["SteinfallKern", .product(name: "ArcadeKern", package: "ArcadeKern"), .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "SteinfallKernTests", dependencies: ["SteinfallKern"]),
    ],
    swiftLanguageModes: [.v5]
)
