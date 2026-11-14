// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Stufenstapel: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielStufenstapel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielStufenstapel", targets: ["SpielStufenstapel"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "StufenstapelKern"),
        .target(name: "SpielStufenstapel", dependencies: ["StufenstapelKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "StufenstapelKernTests", dependencies: ["StufenstapelKern"]),
    ],
    swiftLanguageModes: [.v5]
)
