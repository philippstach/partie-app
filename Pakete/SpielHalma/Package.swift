// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Halma: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielHalma",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielHalma", targets: ["SpielHalma"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "HalmaKern"),
        .target(name: "SpielHalma", dependencies: ["HalmaKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "HalmaKernTests", dependencies: ["HalmaKern", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
