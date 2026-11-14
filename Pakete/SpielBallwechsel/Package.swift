// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Ballwechsel: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielBallwechsel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielBallwechsel", targets: ["SpielBallwechsel"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../ArcadeKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "BallwechselKern", dependencies: [.product(name: "ArcadeKern", package: "ArcadeKern")]),
        .target(name: "SpielBallwechsel", dependencies: ["BallwechselKern", .product(name: "ArcadeKern", package: "ArcadeKern"), .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "BallwechselKernTests", dependencies: ["BallwechselKern"]),
    ],
    swiftLanguageModes: [.v5]
)
