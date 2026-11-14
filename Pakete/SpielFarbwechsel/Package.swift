// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Farbwechsel: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielFarbwechsel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielFarbwechsel", targets: ["SpielFarbwechsel"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "FarbwechselKern"),
        .target(name: "SpielFarbwechsel", dependencies: ["FarbwechselKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "FarbwechselKernTests", dependencies: ["FarbwechselKern"]),
    ],
    swiftLanguageModes: [.v5]
)
