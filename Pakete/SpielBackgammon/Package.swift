// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Backgammon: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielBackgammon",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielBackgammon", targets: ["SpielBackgammon"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "BackgammonKern"),
        .target(name: "SpielBackgammon", dependencies: ["BackgammonKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "BackgammonKernTests", dependencies: ["BackgammonKern", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
