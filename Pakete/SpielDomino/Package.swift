// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Domino: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielDomino",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielDomino", targets: ["SpielDomino"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "DominoKern"),
        .target(name: "SpielDomino", dependencies: ["DominoKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "DominoKernTests", dependencies: ["DominoKern"]),
    ],
    swiftLanguageModes: [.v5]
)
