// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// SpieleKern: Logik und Daten der Sammlung „Partie“ (Spieler, Statistik, Würfel, Spielmodul-Protokoll).
let package = Package(
    name: "SpieleKern",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpieleKern", targets: ["SpieleKern"])],
    dependencies: [.package(path: "../Baukasten"), .package(path: "../ArcadeKern")],
    targets: [
        .target(name: "SpieleKern", dependencies: [.product(name: "ArcadeKern", package: "ArcadeKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "Baukasten", package: "Baukasten")]),
        .testTarget(name: "SpieleKernTests", dependencies: ["SpieleKern"]),
    ]
)
