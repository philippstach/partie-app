// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Esel: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielEsel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielEsel", targets: ["SpielEsel"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "EselKern", dependencies: [.product(name: "SpieleKern", package: "SpieleKern")]),
        .target(name: "SpielEsel", dependencies: ["EselKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "EselKernTests", dependencies: ["EselKern"]),
    ],
    swiftLanguageModes: [.v5]
)
