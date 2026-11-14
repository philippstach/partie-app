// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Steckspiel: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSteckspiel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSteckspiel", targets: ["SpielSteckspiel"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "SteckspielKern"),
        .target(name: "SpielSteckspiel", dependencies: ["SteckspielKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "SteckspielKernTests", dependencies: ["SteckspielKern"]),
    ],
    swiftLanguageModes: [.v5]
)
