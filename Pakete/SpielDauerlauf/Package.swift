// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Dauerlauf: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielDauerlauf",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielDauerlauf", targets: ["SpielDauerlauf"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../ArcadeKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "DauerlaufKern", dependencies: [.product(name: "ArcadeKern", package: "ArcadeKern")]),
        .target(name: "SpielDauerlauf", dependencies: ["DauerlaufKern", .product(name: "ArcadeKern", package: "ArcadeKern"), .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "DauerlaufKernTests", dependencies: ["DauerlaufKern"]),
    ],
    swiftLanguageModes: [.v5]
)
