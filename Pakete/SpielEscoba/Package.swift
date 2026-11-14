// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Escoba: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielEscoba",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielEscoba", targets: ["SpielEscoba"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "EscobaKern"),
        .target(name: "SpielEscoba", dependencies: ["EscobaKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "EscobaKernTests", dependencies: ["EscobaKern"]),
    ],
    swiftLanguageModes: [.v5]
)
