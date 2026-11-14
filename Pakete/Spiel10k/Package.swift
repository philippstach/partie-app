// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// 10k behält vorerst seine eigene Oberfläche (altes Design); nur das Modul-Ziel kennt SpieleKern/KlarGlas.
let package = Package(
    name: "Spiel10k",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "Spiel10kModul", targets: ["Spiel10kModul"]), .library(name: "Spiel10k", targets: ["Spiel10k"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "Spiel10k", dependencies: [.product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpieleKern", package: "SpieleKern")]),
        .target(name: "Spiel10kModul", dependencies: ["Spiel10k", .product(name: "SpieleKern", package: "SpieleKern")]),
        .testTarget(name: "Spiel10kTests", dependencies: ["Spiel10k"]),
    ]
)
