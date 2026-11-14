// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Wendespiel: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielWendespiel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielWendespiel", targets: ["SpielWendespiel"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "WendespielKern"),
        .target(name: "SpielWendespiel", dependencies: ["WendespielKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "WendespielKernTests", dependencies: ["WendespielKern", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
