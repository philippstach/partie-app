// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Schwimmen : die eine Fassung des Spiels in der Sammlung.
// Regeln (Kern.swift) getrennt von der Oberfläche; `swift test` auf dem Mac ohne Simulator.
let package = Package(
    name: "SpielSchwimmen",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSchwimmen", targets: ["SpielSchwimmen"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../SpielHilfen"),
        .package(path: "../../Test/DesignBilder"),
    ],
    targets: [
        .target(name: "SpielSchwimmen", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
            .product(name: "SpielHilfen", package: "SpielHilfen"),
        ]),
        .testTarget(name: "SpielSchwimmenTests", dependencies: ["SpielSchwimmen", .product(name: "DesignBilder", package: "DesignBilder")]),
    ],
    swiftLanguageModes: [.v5]
)
