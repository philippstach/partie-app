// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Mauerbrecher: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielMauerbrecher",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielMauerbrecher", targets: ["SpielMauerbrecher"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../ArcadeKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "MauerbrecherKern", dependencies: [.product(name: "ArcadeKern", package: "ArcadeKern")]),
        .target(name: "SpielMauerbrecher", dependencies: ["MauerbrecherKern", .product(name: "ArcadeKern", package: "ArcadeKern"), .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "MauerbrecherKernTests", dependencies: ["MauerbrecherKern"]),
    ],
    swiftLanguageModes: [.v5]
)
