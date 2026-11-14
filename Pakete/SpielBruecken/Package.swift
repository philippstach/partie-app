// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Bruecken: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielBruecken",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielBruecken", targets: ["SpielBruecken"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "BrueckenKern"),
        .target(name: "SpielBruecken", dependencies: ["BrueckenKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "BrueckenKernTests", dependencies: ["BrueckenKern"]),
    ],
    swiftLanguageModes: [.v5]
)
