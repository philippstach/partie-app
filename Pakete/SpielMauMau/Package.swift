// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Mau-Mau : die eine Fassung des Spiels in der Sammlung.
// Kern in `KernMauMau`, Tisch und Fächer-Hand im gemeinsamen Baustein `AblegeKarten` (mit Elfer raus).
let package = Package(
    name: "SpielMauMau",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielMauMau", targets: ["SpielMauMau"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../AblegeKarten"),
        .package(path: "../KernMauMau"),
    ],
    targets: [
        .target(name: "SpielMauMau", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
            .product(name: "AblegeKarten", package: "AblegeKarten"),
            .product(name: "MauMauKern", package: "KernMauMau"),
        ]),
        .testTarget(name: "SpielMauMauTests", dependencies: ["SpielMauMau", .product(name: "MauMauKern", package: "KernMauMau"), .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
