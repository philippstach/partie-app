// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// Reiner Regelkern von Viererreihe ohne UIKit/SwiftUI: dieselben Dateien wie in SpielViererreihe/Kern (Verweise), damit die Regeln mit `swift test` laufen.
// Rätsel-Daten: `PARTIE_PARTIEN=$PWD/../../App/Ressourcen/Daten:$PWD/Shared/inhalt:$PWD/Shared/regeltests swift test` (siehe Model/Inhaltssuche.swift).
let package = Package(
    name: "KernViererreihe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielViererreihe", targets: ["SpielViererreihe"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
    ],
    targets: [
        .target(name: "SpielViererreihe", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ]),
        .testTarget(name: "ViererreiheKernTests", dependencies: ["SpielViererreihe", .product(name: "SpieleKern", package: "SpieleKern")]),
    ]
)
