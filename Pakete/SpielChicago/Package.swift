// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Chicago: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielChicago",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielChicago", targets: ["SpielChicago"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "ChicagoKern"),
        .target(name: "SpielChicago", dependencies: ["ChicagoKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "ChicagoKernTests", dependencies: ["ChicagoKern"]),
    ],
    swiftLanguageModes: [.v5]
)
