// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// Reiner Regelkern von Schocken ohne UIKit: dieselben Dateien wie in SpielSchocken (Verweise), damit Wertung, Joker und Zustand mit `swift test` laufen.
let package = Package(
    name: "KernSchocken",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSchocken", targets: ["SpielSchocken"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
    ],
    targets: [
        .target(name: "SpielSchocken", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ]),
        .testTarget(name: "SchockenKernTests", dependencies: ["SpielSchocken"]),
    ]
)
