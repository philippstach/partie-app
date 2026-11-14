// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// CrazyEights: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielCrazyEights",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielCrazyEights", targets: ["SpielCrazyEights"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "CrazyEightsKern", dependencies: [.product(name: "SpieleKern", package: "SpieleKern")]),
        .target(name: "SpielCrazyEights", dependencies: ["CrazyEightsKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "CrazyEightsKernTests", dependencies: ["CrazyEightsKern", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
