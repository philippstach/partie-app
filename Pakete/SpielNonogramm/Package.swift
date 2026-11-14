// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Nonogramm: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielNonogramm",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielNonogramm", targets: ["SpielNonogramm"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "NonogrammKern"),
        .target(name: "SpielNonogramm", dependencies: ["NonogrammKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "NonogrammKernTests", dependencies: ["NonogrammKern"]),
    ],
    swiftLanguageModes: [.v5]
)
