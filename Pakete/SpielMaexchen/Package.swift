// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Maexchen: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielMaexchen",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielMaexchen", targets: ["SpielMaexchen"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "MaexchenKern"),
        .target(name: "SpielMaexchen", dependencies: ["MaexchenKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "MaexchenKernTests", dependencies: ["MaexchenKern"]),
    ],
    swiftLanguageModes: [.v5]
)
