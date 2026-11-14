// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// Reiner Regelkern von Yacht ohne UIKit: dieselben Dateien wie in SpielYacht (Verweise), damit Wertung, Joker und Zustand mit `swift test` laufen.
let package = Package(
    name: "KernYacht",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielYacht", targets: ["SpielYacht"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
    ],
    targets: [
        .target(name: "SpielYacht", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ]),
        .testTarget(name: "YachtKernTests", dependencies: ["SpielYacht"]),
    ]
)
